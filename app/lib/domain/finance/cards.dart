import '../../data/db/database.dart';
import 'finance.dart';
import 'finance_enums.dart';

/// Where an invoice stands: "Aberta" (still taking purchases), "Fechada" (waiting for the due day),
/// "Paga", "Vencida" (past the due day with something left) or without purchases.
enum InvoiceStatus { open, closed, paid, overdue, empty }

/// One invoice of a card: its purchases (and refunds), what was paid and what is left.
class InvoiceSummary {
  const InvoiceSummary({
    required this.card,
    required this.month,
    required this.closing,
    required this.due,
    required this.entries,
    required this.payments,
    required this.status,
  });

  final FinCard card;

  /// The due month's first day: the invoice's name.
  final DateTime month;
  final DateTime closing;
  final DateTime due;
  final List<FinEntry> entries;
  final List<FinCardPayment> payments;
  final InvoiceStatus status;

  /// Purchases minus refunds (income on the card).
  int get total => entries.fold(0, (sum, e) => sum + (e.kind == FinKind.expense ? e.amount : -e.amount));
  int get paid => payments.fold(0, (sum, p) => sum + p.amount);
  int get remaining => total - paid;
}

InvoiceSummary invoiceOf(FinanceSnapshot s, FinCard card, DateTime month, DateTime today) {
  final entries = [
    for (final e in s.entries)
      if (e.cardId == card.id && e.invoiceMonth != null && _sameMonth(finDay(e.invoiceMonth!), month)) e,
  ];
  final payments = [
    for (final p in s.cardPayments)
      if (p.cardId == card.id && _sameMonth(finDay(p.invoiceMonth), month)) p,
  ]..sort((a, b) => b.date.compareTo(a.date));
  final closing = invoiceClosing(card, month), due = invoiceDue(card, month);
  final summary = InvoiceSummary(
    card: card,
    month: DateTime(month.year, month.month),
    closing: closing,
    due: due,
    entries: entries,
    payments: payments,
    status: InvoiceStatus.empty,
  );
  final day = DateTime(today.year, today.month, today.day);
  final status = entries.isEmpty && payments.isEmpty
      ? InvoiceStatus.empty
      : summary.remaining <= 0 && !day.isBefore(closing)
      ? InvoiceStatus.paid
      : day.isBefore(closing)
      ? InvoiceStatus.open
      : day.isAfter(due) && summary.remaining > 0
      ? InvoiceStatus.overdue
      : InvoiceStatus.closed;
  return InvoiceSummary(card: card, month: summary.month, closing: closing, due: due, entries: entries, payments: payments, status: status);
}

bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// The invoice that takes purchases today.
DateTime currentInvoiceMonth(FinCard card, DateTime today) => invoiceMonthFor(card, DateTime(today.year, today.month, today.day));

/// The credit in use: everything bought on the card (refunds out) minus everything paid.
int cardUsed(FinanceSnapshot s, FinCard card) {
  var used = 0;
  for (final e in s.entries) {
    if (e.cardId == card.id) used += e.kind == FinKind.expense ? e.amount : -e.amount;
  }
  for (final p in s.cardPayments) {
    if (p.cardId == card.id) used -= p.amount;
  }
  return used < 0 ? 0 : used;
}
