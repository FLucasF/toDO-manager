import 'cards.dart';
import 'finance.dart';
import 'finance_enums.dart';
import 'loans.dart';
import 'recurring.dart';

/// What falls due on a day of the calendar: a recurring bill (to pay or to receive), a card
/// invoice, or the day to collect a loan.
enum FinanceDueKind { bill, income, invoice, loan }

class FinanceDue {
  const FinanceDue({required this.kind, required this.id, required this.name, required this.amount, required this.day, required this.done});

  final FinanceDueKind kind;

  /// The recurring bill's, card's or loan's id.
  final String id;
  final String name;

  /// What is (or was) to pay or receive that day.
  final int amount;
  final DateTime day;

  /// Paid, received or collected.
  final bool done;
}

/// The due days from [from] (included) to [to] (excluded): every occurrence of the recurring bills,
/// the invoices with purchases (on their due day) and the loans' collection day.
List<FinanceDue> financeDues(FinanceSnapshot s, DateTime from, DateTime to, DateTime today) {
  final last = to.subtract(const Duration(days: 1));
  bool inRange(DateTime day) => !day.isBefore(from) && !day.isAfter(last);
  final dues = <FinanceDue>[
    for (final o in occurrences(s, from, last, today))
      FinanceDue(
        kind: o.recurring.kind == FinKind.income ? FinanceDueKind.income : FinanceDueKind.bill,
        id: o.recurring.id,
        name: o.recurring.description,
        amount: o.entry?.amount ?? o.recurring.amount,
        day: o.due,
        done: o.status == OccurrenceStatus.paid,
      ),
  ];
  for (final card in s.cards) {
    if (card.archivedAt != null) continue;
    // An invoice is due in its own month: look at the months the range touches.
    for (var m = DateTime(from.year, from.month); !m.isAfter(last); m = DateTime(m.year, m.month + 1)) {
      final invoice = invoiceOf(s, card, m, today);
      if (invoice.entries.isEmpty || !inRange(invoice.due)) continue;
      dues.add(
        FinanceDue(
          kind: FinanceDueKind.invoice,
          id: card.id,
          name: card.name,
          amount: invoice.remaining > 0 ? invoice.remaining : invoice.total,
          day: invoice.due,
          done: invoice.status == InvoiceStatus.paid,
        ),
      );
    }
  }
  for (final l in loanSummaries(s, today)) {
    final due = finDay(l.loan.dueOn);
    if (l.loan.archivedAt != null || !inRange(due)) continue;
    dues.add(
      FinanceDue(
        kind: FinanceDueKind.loan,
        id: l.loan.id,
        name: l.loan.borrower,
        amount: l.status == LoanStatus.paid ? l.loan.total : l.balance,
        day: due,
        done: l.status == LoanStatus.paid,
      ),
    );
  }
  return dues..sort((a, b) => a.day.compareTo(b.day));
}
