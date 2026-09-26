import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/finance_repository.dart';
import 'package:task_manager/domain/finance/cards.dart';
import 'package:task_manager/domain/finance/finance.dart';
import 'package:task_manager/domain/finance/finance_enums.dart';
import 'package:task_manager/domain/finance/finance_reminders.dart';
import 'package:task_manager/domain/finance/loans.dart';
import 'package:task_manager/domain/finance/recurring.dart';
import 'package:task_manager/domain/finance/reports.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  // Friday, 2026-09-25.
  final today = DateTime(2026, 9, 25);
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FinanceRepository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
  });
  tearDown(() => db.close());

  FinRecurringsCompanion bill(String name, int amount, int day, {FinFrequency frequency = FinFrequency.monthly, int? month, int? remind = 0}) =>
      FinRecurringsCompanion(
        kind: const Value(FinKind.expense),
        description: Value(name),
        amount: Value(amount),
        frequency: Value(frequency),
        day: Value(day),
        month: Value(month),
        startDate: Value(storedDay(DateTime(2026, 1, 1))),
        remindDaysBefore: Value(remind),
      );

  group('cards', () {
    test('an invoice: open, closed, paid in parts, overdue; refunds lower it; the credit in use', () async {
      final card = await repo.createCard(name: 'Nubank', closingDay: 5, dueDay: 12, creditLimit: 500000);
      await repo.addEntry(kind: FinKind.expense, amount: 30000, date: DateTime(2026, 9, 10), cardId: card);
      await repo.addEntry(kind: FinKind.expense, amount: 20000, date: DateTime(2026, 9, 20), cardId: card);
      await repo.addEntry(kind: FinKind.income, amount: 5000, date: DateTime(2026, 9, 21), cardId: card, description: 'Estorno');
      var s = await repo.load();
      final c = s.cardById[card]!;
      expect(currentInvoiceMonth(c, today), DateTime(2026, 10));
      var october = invoiceOf(s, c, DateTime(2026, 10), today);
      expect((october.total, october.paid, october.remaining, october.status), (45000, 0, 45000, InvoiceStatus.open));
      expect((october.closing, october.due), (DateTime(2026, 10, 5), DateTime(2026, 10, 12)));
      expect(invoiceOf(s, c, DateTime(2026, 10), DateTime(2026, 10, 7)).status, InvoiceStatus.closed);
      expect(invoiceOf(s, c, DateTime(2026, 10), DateTime(2026, 10, 13)).status, InvoiceStatus.overdue);

      await repo.payInvoice(cardId: card, invoiceMonth: DateTime(2026, 10), amount: 40000, date: DateTime(2026, 10, 8));
      s = await repo.load();
      october = invoiceOf(s, c, DateTime(2026, 10), DateTime(2026, 10, 8));
      expect((october.paid, october.remaining, october.status), (40000, 5000, InvoiceStatus.closed));
      expect(cardUsed(s, c), 5000);
      await repo.payInvoice(cardId: card, invoiceMonth: DateTime(2026, 10), amount: 5000, date: DateTime(2026, 10, 9));
      s = await repo.load();
      expect(invoiceOf(s, c, DateTime(2026, 10), DateTime(2026, 10, 20)).status, InvoiceStatus.paid);
      expect(invoiceOf(s, c, DateTime(2026, 11), today).status, InvoiceStatus.empty);
      // Paying is not spending: October's expenses are the purchases alone.
      expect(totalsOf(entriesOfMonth(s, DateTime(2026, 10))).expense, 50000);
    });

    test('new closing and due days move the purchases; a card with purchases is not deleted', () async {
      final card = await repo.createCard(name: 'Inter', closingDay: 5, dueDay: 12);
      await repo.addEntry(kind: FinKind.expense, amount: 9000, date: DateTime(2026, 9, 10), cardId: card, installments: 3);
      await repo.updateCard(card, name: 'Inter', closingDay: 15, dueDay: 22);
      final s = await repo.load();
      final months = [for (final e in s.entries..sort((a, b) => a.installmentIndex!.compareTo(b.installmentIndex!))) finDay(e.invoiceMonth!)];
      expect(months, [DateTime(2026, 9), DateTime(2026, 10), DateTime(2026, 11)]);
      expect(await repo.deleteCard(card), isFalse);
      final empty = await repo.createCard(name: 'Vazio', closingDay: 1, dueDay: 8);
      expect(await repo.deleteCard(empty), isTrue);
    });
  });

  group('recurring bills', () {
    test('due days: monthly on the day (the last one in short months), yearly in its month, within start and end', () async {
      await repo.createRecurring(bill('Aluguel', 150000, 31));
      await repo.createRecurring(bill('IPVA', 90000, 10, frequency: FinFrequency.yearly, month: 3));
      final s = await repo.load();
      final rent = s.recurrings.firstWhere((r) => r.description == 'Aluguel');
      expect(dueDays(rent, DateTime(2026, 1, 1), DateTime(2026, 4, 30)), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
      final tax = s.recurrings.firstWhere((r) => r.description == 'IPVA');
      expect(dueDays(tax, DateTime(2026, 1, 1), DateTime(2027, 12, 31)), [DateTime(2026, 3, 10), DateTime(2027, 3, 10)]);
      await repo.updateRecurring(rent.id, FinRecurringsCompanion(endDate: Value(storedDay(DateTime(2026, 2, 15)))));
      final ended = (await repo.load()).recurrings.firstWhere((r) => r.description == 'Aluguel');
      expect(dueDays(ended, DateTime(2026, 1, 1), DateTime(2026, 4, 30)), [DateTime(2026, 1, 31)]);
    });

    test('paying an occurrence creates the entry; unpaid past ones are overdue; deleting keeps the entries', () async {
      final internet = await repo.createRecurring(bill('Internet', 10000, 10));
      var s = await repo.load();
      var september = occurrences(s, DateTime(2026, 9), DateTime(2026, 9, 30), today);
      expect(september.single.status, OccurrenceStatus.overdue);
      expect(overdueOccurrences(s, today).map((o) => o.due), [for (var m = 1; m <= 9; m++) DateTime(2026, m, 10)]);

      await repo.addEntry(
        kind: FinKind.expense,
        amount: 10990,
        date: DateTime(2026, 9, 25),
        description: 'Internet',
        recurringId: internet,
        recurringDue: DateTime(2026, 9, 10),
      );
      s = await repo.load();
      september = occurrences(s, DateTime(2026, 9), DateTime(2026, 9, 30), today);
      expect((september.single.status, september.single.entry?.amount), (OccurrenceStatus.paid, 10990));
      expect(occurrences(s, DateTime(2026, 10), DateTime(2026, 10, 31), today).single.status, OccurrenceStatus.pending);

      await repo.deleteRecurring(internet);
      s = await repo.load();
      expect(s.recurrings, isEmpty);
      expect(s.entries.single.recurringId, isNull);
    });
  });

  group('loans', () {
    test('paid at once with a profit; partial payments bring profit in proportion; overdue then paid', () async {
      final id = await repo.createLoan(
        borrower: 'João',
        principal: 100000,
        total: 130000,
        lentOn: DateTime(2026, 8, 1),
        dueOn: DateTime(2026, 9, 20),
      );
      var l = loanSummaries(await repo.load(), today).single;
      expect((l.interest, l.rate, l.balance, l.status, l.daysLate), (30000, 3000, 130000, LoanStatus.overdue, 5));
      await repo.addLoanPayment(loanId: id, amount: 13000, date: DateTime(2026, 9, 22));
      l = loanSummaries(await repo.load(), today).single;
      expect((l.received, l.interestReceived, l.balance), (13000, 3000, 117000));
      await repo.addLoanPayment(loanId: id, amount: 117000, date: DateTime(2026, 9, 25));
      l = loanSummaries(await repo.load(), today).single;
      expect((l.status, l.interestReceived, l.balance), (LoanStatus.paid, 30000, 0));
    });

    test('the overview; deleting a loan takes its payments, and undo brings both back', () async {
      final paid = await repo.createLoan(borrower: 'Ana', principal: 50000, total: 60000, lentOn: DateTime(2026, 7, 1), dueOn: DateTime(2026, 8, 1));
      await repo.addLoanPayment(loanId: paid, amount: 60000, date: DateTime(2026, 8, 1));
      await repo.createLoan(borrower: 'Beto', principal: 100000, total: 120000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 9, 10));
      final carla = await repo.createLoan(
        borrower: 'Carla',
        principal: 20000,
        total: 25000,
        lentOn: DateTime(2026, 9, 1),
        dueOn: DateTime(2026, 12, 1),
      );
      await repo.addLoanPayment(loanId: carla, amount: 5000, date: DateTime(2026, 9, 20));
      final o = loansOverview(loanSummaries(await repo.load(), today));
      expect((o.lentOpen, o.lentTotal, o.toReceive, o.overdue, o.open, o.overdueCount), (120000, 170000, 140000, 120000, 2, 1));
      // Ana's 10.000 + Carla's 1.000 (5.000 × 5/25).
      expect(o.interestReceived, 11000);
      expect(o.interestToCome, 20000 + 4000);

      await repo.deleteLoan(carla);
      var s = await repo.load();
      expect(s.loans.map((l) => l.borrower), isNot(contains('Carla')));
      expect(s.loanPayments.where((p) => p.loanId == carla), isEmpty);
      await repo.restoreLoan(carla);
      s = await repo.load();
      expect(loanSummaries(s, today).firstWhere((l) => l.loan.id == carla).received, 5000);
    });
  });

  group('reports', () {
    test('expenses by category, six months of income and expenses, one month against another', () async {
      final market = await repo.createCategory(name: 'Mercado', kind: FinKind.expense);
      final fun = await repo.createCategory(name: 'Lazer', kind: FinKind.expense);
      await repo.addEntry(kind: FinKind.expense, amount: 30000, date: DateTime(2026, 8, 5), categoryId: market);
      await repo.addEntry(kind: FinKind.expense, amount: 45000, date: DateTime(2026, 9, 5), categoryId: market);
      await repo.addEntry(kind: FinKind.expense, amount: 10000, date: DateTime(2026, 9, 6), categoryId: fun);
      await repo.addEntry(kind: FinKind.expense, amount: 2000, date: DateTime(2026, 9, 7));
      await repo.addEntry(kind: FinKind.income, amount: 500000, date: DateTime(2026, 9, 1));
      final s = await repo.load();
      expect(
        [for (final x in expensesByCategory(s, DateTime(2026, 9))) (x.category?.name, x.amount)],
        [('Mercado', 45000), ('Lazer', 10000), (null, 2000)],
      );
      final months = monthlyTotals(s, DateTime(2026, 9), 6);
      expect(months.map((m) => m.month), [for (var m = 4; m <= 9; m++) DateTime(2026, m)]);
      expect((months.last.totals.income, months.last.totals.expense), (500000, 57000));
      expect(months[4].totals.expense, 30000);
      final compared = compareMonths(s, DateTime(2026, 8), DateTime(2026, 9));
      expect([for (final r in compared) (r.category?.name, r.first, r.second)], [('Mercado', 30000, 45000), ('Lazer', 0, 10000), (null, 0, 2000)]);
      expect(changeBasisPoints(30000, 45000), 5000);
      expect(changeBasisPoints(0, 100), isNull);
    });
  });

  group('reminders', () {
    test('bills before their due day at 9:00 until paid; loans on the due day and while late', () async {
      final now = DateTime(2026, 9, 25, 10);
      await repo.createRecurring(bill('Internet', 10000, 28, remind: 3));
      await repo.createRecurring(bill('Luz', 20000, 30));
      await repo.createRecurring(bill('Água', 5000, 27, remind: null));
      await repo.createLoan(borrower: 'João', principal: 100000, total: 110000, lentOn: DateTime(2026, 9, 1), dueOn: DateTime(2026, 9, 26));
      final plan = planFinanceReminders(await repo.load(), now, title: (a) => '${a.kind.name}:${a.name}', body: (a) => '${a.amount}', days: 35);
      final lines = [for (final r in plan) '${r.title} ${r.at.month}/${r.at.day} ${r.at.hour}h'];
      // Internet: 3 days before the 28th was the 25th at 9:00, already gone; October's comes on 10/25.
      expect(lines, containsAll(['billSoon:Internet 10/25 9h', 'billDue:Luz 9/30 9h', 'billDue:Luz 10/30 9h', 'loanDue:João 9/26 9h']));
      expect(lines, contains('loanLate:João 9/27 9h'));
      expect(lines, contains('loanLate:João 10/4 9h'));
      expect(lines.where((l) => l.contains('Água')), isEmpty);
      expect(lines.where((l) => l.contains('Internet 9/25')), isEmpty);
      expect(plan.every((r) => r.isFinance && r.body != null), isTrue);
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
    });
  });
}
