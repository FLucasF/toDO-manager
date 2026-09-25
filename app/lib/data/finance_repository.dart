import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/ids.dart';
import '../core/sort_order.dart';
import '../domain/finance/finance.dart';
import '../domain/finance/finance_enums.dart';
import '../domain/finance/money.dart';
import 'db/database.dart';

/// A default category: name, emoji and kind.
typedef DefaultCategory = ({String name, String icon, FinKind kind});

/// Every write of Finanças. Kept apart from [Repository]: finance changes don't reload the tasks,
/// nor the other way round.
class FinanceRepository {
  FinanceRepository(this._db, {this._clock = const SystemClock()});

  final AppDatabase _db;
  final Clock _clock;

  DateTime get _now => _clock.now().toUtc();

  // ------------------------------------------------------------------ reading

  /// A fresh snapshot on every change to a finance table. The query text must differ from the
  /// tasks' `SELECT 1`: drift shares one stream between identical queries, whatever tables they read.
  Stream<FinanceSnapshot> watch() => _db
      .customSelect(
        'SELECT 1 AS finance',
        readsFrom: {_db.finCategories, _db.finCards, _db.finRecurrings, _db.finEntries, _db.finCardPayments, _db.loans, _db.loanPayments},
      )
      .watch()
      .asyncMap((_) => load());

  Future<FinanceSnapshot> load() => _db.transaction(() async {
    final categories =
        await (_db.select(_db.finCategories)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
            .get();
    final cards =
        await (_db.select(_db.finCards)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
            .get();
    final recurrings =
        await (_db.select(_db.finRecurrings)
              ..where((r) => r.deletedAt.isNull())
              ..orderBy([(r) => OrderingTerm(expression: r.sortOrder)]))
            .get();
    final entries =
        await (_db.select(_db.finEntries)
              ..where((e) => e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm.desc(e.date), (e) => OrderingTerm.desc(e.createdAt)]))
            .get();
    final cardPayments = await (_db.select(_db.finCardPayments)..where((p) => p.deletedAt.isNull())).get();
    final loans =
        await (_db.select(_db.loans)
              ..where((l) => l.deletedAt.isNull())
              ..orderBy([(l) => OrderingTerm(expression: l.dueOn)]))
            .get();
    final loanPayments = await (_db.select(_db.loanPayments)..where((p) => p.deletedAt.isNull())).get();
    return FinanceSnapshot(
      categories: categories,
      cards: cards,
      recurrings: recurrings,
      entries: entries,
      cardPayments: cardPayments,
      loans: loans,
      loanPayments: loanPayments,
    );
  });

  // ------------------------------------------------------------------ categories

  /// The default categories, created when there are none yet (the first time Finanças opens).
  Future<void> seedCategories(List<DefaultCategory> defaults) => _db.transaction(() async {
    final any = await (_db.select(_db.finCategories)..limit(1)).getSingleOrNull();
    if (any != null) return;
    for (final c in defaults) {
      await createCategory(name: c.name, kind: c.kind, icon: c.icon);
    }
  });

  Future<String> createCategory({required String name, required FinKind kind, String icon = '', String? color, int? monthlyLimit}) async {
    final id = newId();
    final last = await (_db.selectOnly(
      _db.finCategories,
    )..addColumns([_db.finCategories.sortOrder.max()])).map((r) => r.read(_db.finCategories.sortOrder.max())).getSingle();
    await _db
        .into(_db.finCategories)
        .insert(
          FinCategoriesCompanion.insert(
            id: id,
            createdAt: _now,
            updatedAt: _now,
            name: name.trim(),
            kind: kind,
            icon: Value(icon),
            color: Value(color),
            monthlyLimit: Value(kind == FinKind.expense ? monthlyLimit : null),
            sortOrder: SortOrder.after(last),
          ),
        );
    return id;
  }

  Future<void> updateCategory(String id, {required String name, required String icon, String? color, int? monthlyLimit}) =>
      (_db.update(_db.finCategories)..where((c) => c.id.equals(id))).write(
        FinCategoriesCompanion(
          name: Value(name.trim()),
          icon: Value(icon),
          color: Value(color),
          monthlyLimit: Value(monthlyLimit),
          updatedAt: Value(_now),
        ),
      );

  /// Deletes a category; its entries and recurring bills are left "Sem categoria".
  Future<void> deleteCategory(String id) => _db.transaction(() async {
    await (_db.update(
      _db.finEntries,
    )..where((e) => e.categoryId.equals(id))).write(FinEntriesCompanion(categoryId: const Value(null), updatedAt: Value(_now)));
    await (_db.update(
      _db.finRecurrings,
    )..where((r) => r.categoryId.equals(id))).write(FinRecurringsCompanion(categoryId: const Value(null), updatedAt: Value(_now)));
    await (_db.delete(_db.finCategories)..where((c) => c.id.equals(id))).go();
  });

  // ------------------------------------------------------------------ entries

  /// "Novo lançamento". A card purchase goes to the invoice of [date], or is split in [installments]
  /// over the invoices that follow ("1/3", "2/3"…). Returns the ids created.
  Future<List<String>> addEntry({
    required FinKind kind,
    required int amount,
    required DateTime date,
    String description = '',
    String? categoryId,
    String? cardId,
    int installments = 1,
    String note = '',
    String? recurringId,
    DateTime? recurringDue,
  }) => _db.transaction(() async {
    final card = cardId == null ? null : await (_db.select(_db.finCards)..where((c) => c.id.equals(cardId))).getSingleOrNull();
    final count = card == null ? 1 : installments.clamp(1, 99);
    final group = count > 1 ? newId() : null;
    final first = card == null ? null : invoiceMonthFor(card, date);
    final ids = <String>[];
    for (final (i, part) in splitCents(amount, count).indexed) {
      final id = newId();
      ids.add(id);
      await _db
          .into(_db.finEntries)
          .insert(
            FinEntriesCompanion.insert(
              id: id,
              createdAt: _now,
              updatedAt: _now,
              kind: kind,
              amount: part,
              date: storedDay(date),
              description: Value(description.trim()),
              categoryId: Value(categoryId),
              cardId: Value(card?.id),
              invoiceMonth: Value(first == null ? null : storedDay(DateTime(first.year, first.month + i))),
              installmentGroup: Value(group),
              installmentIndex: Value(group == null ? null : i + 1),
              installmentCount: Value(group == null ? null : count),
              recurringId: Value(recurringId),
              recurringDue: Value(recurringDue == null ? null : storedDay(recurringDue)),
              note: Value(note.trim()),
            ),
          );
    }
    return ids;
  });

  /// Edits one entry. A card purchase moves to the invoice of its new day (or card).
  Future<void> updateEntry(
    String id, {
    required FinKind kind,
    required int amount,
    required DateTime date,
    required String description,
    required String? categoryId,
    required String? cardId,
    required String note,
  }) => _db.transaction(() async {
    final card = cardId == null ? null : await (_db.select(_db.finCards)..where((c) => c.id.equals(cardId))).getSingleOrNull();
    final entry = await (_db.select(_db.finEntries)..where((e) => e.id.equals(id))).getSingle();
    // An installment keeps its place in the series: the n-th invoice after the purchase's.
    final offset = (entry.installmentIndex ?? 1) - 1;
    final first = card == null ? null : invoiceMonthFor(card, date);
    await (_db.update(_db.finEntries)..where((e) => e.id.equals(id))).write(
      FinEntriesCompanion(
        kind: Value(kind),
        amount: Value(amount),
        date: Value(storedDay(date)),
        description: Value(description.trim()),
        categoryId: Value(categoryId),
        cardId: Value(card?.id),
        invoiceMonth: Value(first == null ? null : storedDay(DateTime(first.year, first.month + offset))),
        note: Value(note.trim()),
        updatedAt: Value(_now),
      ),
    );
  });

  /// Deletes entries (to the "Desfazer" of the toast: [restoreEntries]).
  Future<void> deleteEntries(Iterable<String> ids) =>
      (_db.update(_db.finEntries)..where((e) => e.id.isIn(ids))).write(FinEntriesCompanion(deletedAt: Value(_now), updatedAt: Value(_now)));

  Future<void> restoreEntries(Iterable<String> ids) =>
      (_db.update(_db.finEntries)..where((e) => e.id.isIn(ids))).write(FinEntriesCompanion(deletedAt: const Value(null), updatedAt: Value(_now)));

  /// The installments of a card purchase, in order.
  Future<List<String>> installmentIds(String group) async => [
    for (final e
        in await (_db.select(_db.finEntries)
              ..where((e) => e.installmentGroup.equals(group) & e.deletedAt.isNull())
              ..orderBy([(e) => OrderingTerm(expression: e.installmentIndex)]))
            .get())
      e.id,
  ];
}
