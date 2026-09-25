import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/domain/finance/finance.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/finance/money.dart';

FinCard _card({int closing = 5, int due = 12}) =>
    FinCard(id: 'c', createdAt: DateTime.utc(2026), updatedAt: DateTime.utc(2026), name: 'Nubank', closingDay: closing, dueDay: due, sortOrder: 0);

void main() {
  group('money', () {
    test('formats reais with thousands and cents', () {
      expect(formatMoney(0), r'R$ 0,00');
      expect(formatMoney(5), r'R$ 0,05');
      expect(formatMoney(123456), r'R$ 1.234,56');
      expect(formatMoney(100000000), r'R$ 1.000.000,00');
      expect(formatMoney(-2550), r'-R$ 25,50');
      expect(formatMoney(2550, symbol: false), '25,50');
    });

    test('reads what people type', () {
      expect(parseMoney('1.234,56'), 123456);
      expect(parseMoney('1234,5'), 123450);
      expect(parseMoney('1234.56'), 123456);
      expect(parseMoney(r'R$ 12'), 1200);
      expect(parseMoney('12,'), 1200);
      expect(parseMoney('1.234'), 123400);
      expect(parseMoney('0,99'), 99);
      expect(parseMoney(''), isNull);
      expect(parseMoney('abc'), isNull);
      expect(parseMoney('-5'), isNull);
    });

    test('percent in hundredths, and splitting cents without losing any', () {
      expect(formatPercent(1000), '10%');
      expect(formatPercent(1250), '12,5%');
      expect(formatPercent(1205), '12,05%');
      expect(parsePercent('12,5'), 1250);
      expect(parsePercent('10%'), 1000);
      expect(parsePercent('x'), isNull);
      expect(splitCents(10000, 3), [3334, 3333, 3333]);
      expect(splitCents(10000, 3).reduce((a, b) => a + b), 10000);
    });
  });

  group('card invoices', () {
    test('closing on the 5th, due on the 12th: the closing day already goes to the next invoice', () {
      final card = _card();
      expect(invoiceMonthFor(card, DateTime(2026, 9, 3)), DateTime(2026, 9));
      expect(invoiceMonthFor(card, DateTime(2026, 9, 5)), DateTime(2026, 10));
      expect(invoiceMonthFor(card, DateTime(2026, 9, 6)), DateTime(2026, 10));
      expect(invoiceMonthFor(card, DateTime(2026, 12, 20)), DateTime(2027, 1));
      expect(invoiceClosing(card, DateTime(2026, 10)), DateTime(2026, 10, 5));
      expect(invoiceDue(card, DateTime(2026, 10)), DateTime(2026, 10, 12));
    });

    test('closing late in the month, due early in the next', () {
      final card = _card(closing: 28, due: 5);
      expect(invoiceMonthFor(card, DateTime(2026, 9, 10)), DateTime(2026, 10));
      expect(invoiceMonthFor(card, DateTime(2026, 9, 29)), DateTime(2026, 11));
      expect(invoiceClosing(card, DateTime(2026, 10)), DateTime(2026, 9, 28));
      expect(invoiceDue(card, DateTime(2026, 10)), DateTime(2026, 10, 5));
    });

    test('day 31 falls on the last day of shorter months', () {
      final card = _card(closing: 31, due: 10);
      expect(invoiceClosing(card, DateTime(2026, 3)), DateTime(2026, 2, 28));
      expect(invoiceMonthFor(card, DateTime(2026, 2, 28)), DateTime(2026, 4));
      expect(invoiceMonthFor(card, DateTime(2026, 2, 27)), DateTime(2026, 3));
    });
  });

  group('repository and months', () {
    late AppDatabase db;
    late FinanceRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = FinanceRepository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
    });
    tearDown(() => db.close());

    Future<String> addCard() async {
      final now = DateTime.utc(2026);
      await db
          .into(db.finCards)
          .insert(FinCardsCompanion.insert(id: 'card', createdAt: now, updatedAt: now, name: 'Nubank', closingDay: 5, dueDay: 12, sortOrder: 0));
      return 'card';
    }

    test('default categories are created once', () async {
      const defaults = [(name: 'Mercado', icon: '🛒', kind: FinKind.expense), (name: 'Salário', icon: '💰', kind: FinKind.income)];
      await repo.seedCategories(defaults);
      await repo.seedCategories(defaults);
      final s = await repo.load();
      expect(s.categories.map((c) => c.name), ['Mercado', 'Salário']);
      expect(s.categoriesOf(FinKind.income).single.name, 'Salário');
    });

    test('month totals; a card purchase counts in the month of its invoice', () async {
      final card = await addCard();
      await repo.addEntry(kind: FinKind.income, amount: 500000, date: DateTime(2026, 9, 5), description: 'Salário');
      await repo.addEntry(kind: FinKind.expense, amount: 12000, date: DateTime(2026, 9, 10), description: 'Mercado');
      // After the closing (5th): October's invoice.
      await repo.addEntry(kind: FinKind.expense, amount: 30000, date: DateTime(2026, 9, 20), description: 'Tênis', cardId: card);
      final s = await repo.load();
      final september = totalsOf(entriesOfMonth(s, DateTime(2026, 9)));
      expect((september.income, september.expense, september.balance), (500000, 12000, 488000));
      expect(totalsOf(entriesOfMonth(s, DateTime(2026, 10))).expense, 30000);
      expect(countDay(s, s.entries.firstWhere((e) => e.description == 'Tênis')), DateTime(2026, 10, 12));
    });

    test('installments go to the invoices that follow, adding up to the price', () async {
      final card = await addCard();
      final ids = await repo.addEntry(
        kind: FinKind.expense,
        amount: 100000,
        date: DateTime(2026, 9, 3),
        description: 'Geladeira',
        cardId: card,
        installments: 3,
      );
      expect(ids, hasLength(3));
      final s = await repo.load();
      final parts = s.entries.where((e) => e.description == 'Geladeira').toList()..sort((a, b) => a.installmentIndex!.compareTo(b.installmentIndex!));
      expect(
        [for (final e in parts) (finDay(e.invoiceMonth!), e.amount, e.installmentIndex, e.installmentCount)],
        [(DateTime(2026, 9), 33334, 1, 3), (DateTime(2026, 10), 33333, 2, 3), (DateTime(2026, 11), 33333, 3, 3)],
      );
      expect(parts.map((e) => e.installmentGroup).toSet(), hasLength(1));
      expect(await repo.installmentIds(parts.first.installmentGroup!), [for (final e in parts) e.id]);
      // Without a card there are no installments.
      expect(await repo.addEntry(kind: FinKind.expense, amount: 100, date: DateTime(2026, 9, 3), installments: 3), hasLength(1));
    });

    test('editing moves a card purchase to its new invoice, keeping an installment in its place', () async {
      final card = await addCard();
      final ids = await repo.addEntry(kind: FinKind.expense, amount: 20000, date: DateTime(2026, 9, 3), cardId: card, installments: 2);
      await repo.updateEntry(
        ids[1],
        kind: FinKind.expense,
        amount: 10000,
        date: DateTime(2026, 9, 10),
        description: 'Fone',
        categoryId: null,
        cardId: card,
        note: '',
      );
      final second = (await repo.load()).entries.firstWhere((e) => e.id == ids[1]);
      // The 10th is after the closing: first invoice October, so the 2nd installment is November's.
      expect(finDay(second.invoiceMonth!), DateTime(2026, 11));
      expect(second.description, 'Fone');
    });

    test('limits: near from 80%, over past 100%; deleting a category keeps its entries', () async {
      final market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense, monthlyLimit: 50000);
      await repo.createCategory(name: 'Lazer', kind: FinKind.expense);
      await repo.addEntry(kind: FinKind.expense, amount: 39000, date: DateTime(2026, 9, 2), categoryId: market);
      var status = limitsOfMonth(await repo.load(), DateTime(2026, 9)).single;
      expect((status.spent, status.level), (39000, LimitLevel.ok));
      await repo.addEntry(kind: FinKind.expense, amount: 1000, date: DateTime(2026, 9, 3), categoryId: market);
      expect(limitsOfMonth(await repo.load(), DateTime(2026, 9)).single.level, LimitLevel.near);
      await repo.addEntry(kind: FinKind.expense, amount: 10001, date: DateTime(2026, 9, 4), categoryId: market);
      status = limitsOfMonth(await repo.load(), DateTime(2026, 9)).single;
      expect((status.spent, status.level), (50001, LimitLevel.over));
      // October starts from zero.
      expect(limitsOfMonth(await repo.load(), DateTime(2026, 10)).single.spent, 0);

      await repo.deleteCategory(market);
      final s = await repo.load();
      expect(s.categories.map((c) => c.name), ['Lazer']);
      expect(s.entries.where((e) => e.categoryId == null), hasLength(3));
    });

    test('history filters by period, category, kind and words; delete and undo', () async {
      final market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense);
      await repo.addEntry(kind: FinKind.expense, amount: 100, date: DateTime(2026, 8, 30), description: 'Pão', categoryId: market);
      final milk = await repo.addEntry(kind: FinKind.expense, amount: 200, date: DateTime(2026, 9, 1), description: 'Leite', categoryId: market);
      await repo.addEntry(kind: FinKind.expense, amount: 300, date: DateTime(2026, 9, 2), description: 'Uber');
      await repo.addEntry(kind: FinKind.income, amount: 400, date: DateTime(2026, 9, 3), description: 'Pix do João');
      var s = await repo.load();
      List<String> find(EntryFilter f) => [for (final e in filterEntries(s, f)) e.description];
      final september = (from: DateTime(2026, 9), to: DateTime(2026, 9, 30));
      expect(find(EntryFilter(from: september.from, to: september.to)), ['Pix do João', 'Uber', 'Leite']);
      expect(find(EntryFilter(from: september.from, to: september.to, categoryIds: {market})), ['Leite']);
      expect(find(EntryFilter(from: september.from, to: september.to, categoryIds: {''})), ['Pix do João', 'Uber']);
      expect(find(EntryFilter(from: september.from, to: september.to, kind: FinKind.income)), ['Pix do João']);
      expect(find(EntryFilter(from: DateTime(2026, 8), to: september.to, text: 'pão')), ['Pão']);

      await repo.deleteEntries(milk);
      s = await repo.load();
      expect(find(EntryFilter(from: september.from, to: september.to)), ['Pix do João', 'Uber']);
      await repo.restoreEntries(milk);
      s = await repo.load();
      expect(find(EntryFilter(from: september.from, to: september.to)), hasLength(3));
    });
  });
}
