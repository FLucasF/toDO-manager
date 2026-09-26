import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/finance/cards.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import 'entries_tab.dart';
import 'finance_widgets.dart';

/// "Cartões" without a card yet.
class NoCardsBody extends StatelessWidget {
  const NoCardsBody({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).finNoCards,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.tt.textTertiary),
          ),
          const SizedBox(height: 16),
          CreateButton(label: AppLocalizations.of(context).finNewCard, onPressed: () => unawaited(showCardForm(context))),
        ],
      ),
    ),
  );
}

/// A card's invoice: its figures (Total, Pago, Falta pagar), its status, closing and due days and
/// "Pagar fatura"; then its purchases laid out as the Agenda (by the day bought) and its payments.
class CardInvoiceBody extends ConsumerWidget {
  const CardInvoiceBody({super.key, required this.card, required this.month, required this.today});

  final FinCard card;
  final DateTime month;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final invoice = invoiceOf(s, card, month, today);
    final limit = card.creditLimit;
    final used = cardUsed(s, card);
    final (statusLabel, statusColor) = switch (invoice.status) {
      InvoiceStatus.open => (t.finInvoiceOpen, tt.primary),
      InvoiceStatus.closed => (t.finInvoiceClosed, tt.palette.priorityMedium),
      InvoiceStatus.paid => (t.finInvoicePaid, tt.palette.green),
      InvoiceStatus.overdue => (t.finInvoiceOverdue, tt.overdue),
      InvoiceStatus.empty => (t.finInvoiceEmpty, tt.textTertiary),
    };
    final byDay = <DateTime, List<FinEntry>>{};
    for (final e in invoice.entries) {
      byDay.putIfAbsent(finDay(e.date), () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        Row(
          children: [
            Icon(Icons.credit_card, size: 18, color: tt.textSecondary),
            const SizedBox(width: 8),
            Text(
              card.name,
              style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
            ),
            IconButton(
              tooltip: t.finEditCard,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_outlined, size: 18, color: tt.textSecondary),
              onPressed: () => unawaited(showCardForm(context, editing: card)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: TtText.small, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            if (invoice.remaining > 0)
              FilledButton.icon(
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(t.finPayInvoice),
                onPressed: () => unawaited(
                  showFinanceDialog<void>(
                    context,
                    builder: (_) => _PaymentForm(invoice: invoice, today: today),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FigureStrip(
          figures: [
            (label: t.finInvoiceTotal, value: formatMoney(invoice.total), color: null, hint: null),
            (label: t.finInvoicePaidAmount, value: formatMoney(invoice.paid), color: tt.palette.green, hint: null),
            (
              label: t.finInvoiceRemaining,
              value: formatMoney(invoice.remaining < 0 ? 0 : invoice.remaining),
              color: invoice.remaining > 0 ? tt.overdue : null,
              hint: t.finInvoiceDates(DateLabels.numeric(invoice.closing, withYear: false), DateLabels.numeric(invoice.due, withYear: false)),
            ),
            if (limit != null)
              (
                label: t.finCreditAvailable,
                value: formatMoney(limit - used < 0 ? 0 : limit - used),
                color: used > limit ? tt.overdue : null,
                hint: t.finCardUsed(formatMoney(used), formatMoney(limit)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              t.finInvoiceEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final (i, day) in days.indexed) ...[
          if (i > 0) Divider(height: 1, color: tt.divider),
          AgendaBlock(
            day: day,
            today: today,
            children: [for (final e in byDay[day]!) EntryLine(entry: e, snapshot: s, showCard: false)],
          ),
        ],
        if (invoice.payments.isNotEmpty) ...[
          BodyHeading(t.finPayments),
          for (final p in invoice.payments)
            AgendaLine(
              color: tt.palette.green,
              secondary: DateLabels.numeric(finDay(p.date)),
              title: formatMoney(p.amount),
              onTap: () => unawaited(
                showFinanceDialog<void>(
                  context,
                  builder: (_) => _PaymentForm(invoice: invoice, today: today, editing: p),
                ),
              ),
              trailing: IconButton(
                tooltip: t.actionDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: tt.textTertiary),
                onPressed: () async {
                  final repo = ref.read(financeRepositoryProvider);
                  await repo.deleteCardPayment(p.id);
                  if (context.mounted) {
                    showToast(
                      context,
                      t.finPaymentDeleted,
                      undo: () => repo.deleteCardPayment(p.id, restore: true),
                      redo: () => repo.deleteCardPayment(p.id),
                    );
                  }
                },
              ),
            ),
        ],
      ],
    );
  }
}

/// "Pagar fatura": the amount (what is left, to begin with) and the day; [editing] a payment made.
class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.invoice, required this.today, this.editing});

  final InvoiceSummary invoice;
  final DateTime today;
  final FinCardPayment? editing;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  late final _amount = TextEditingController(text: formatMoney(widget.editing?.amount ?? widget.invoice.remaining, symbol: false));
  late DateTime _date = widget.editing == null ? widget.today : finDay(widget.editing!.date);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return;
    final repo = ref.read(financeRepositoryProvider);
    if (widget.editing case final p?) {
      await repo.updateCardPayment(p.id, amount: amount, date: _date);
    } else {
      await repo.payInvoice(cardId: widget.invoice.card.id, invoiceMonth: widget.invoice.month, amount: amount, date: _date);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete(FinCardPayment p) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    final page = Navigator.of(context).context;
    Navigator.pop(context);
    await repo.deleteCardPayment(p.id);
    if (page.mounted) {
      showToast(page, t.finPaymentDeleted, undo: () => repo.deleteCardPayment(p.id, restore: true), redo: () => repo.deleteCardPayment(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: widget.editing == null ? t.finPayInvoice : t.finEditPayment,
          onSave: () => unawaited(_save()),
          onDelete: switch (widget.editing) {
            final p? => () => unawaited(_delete(p)),
            null => null,
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(controller: _amount, label: t.finPaymentAmount, autofocus: true, onSubmitted: () => unawaited(_save())),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: tt.textSecondary),
                title: Text(
                  t.finPaymentDate,
                  style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
                ),
                subtitle: Text(DateLabels.numeric(_date), style: TextStyle(color: tt.text)),
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Novo cartão" / "Editar cartão": name, closing and due days, credit limit. Returns the new id.
Future<String?> showCardForm(BuildContext context, {FinCard? editing}) =>
    showFinanceDialog<String>(context, builder: (_) => _CardForm(editing: editing));

class _CardForm extends ConsumerStatefulWidget {
  const _CardForm({this.editing});

  final FinCard? editing;

  @override
  ConsumerState<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<_CardForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _limit = TextEditingController(
    text: widget.editing?.creditLimit == null ? '' : formatMoney(widget.editing!.creditLimit!, symbol: false),
  );
  late int _closing = widget.editing?.closingDay ?? 1;
  late int _due = widget.editing?.dueDay ?? 10;

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final limit = parseMoney(_limit.text);
    final repo = ref.read(financeRepositoryProvider);
    final editing = widget.editing;
    String? id;
    if (editing == null) {
      id = await repo.createCard(name: name, closingDay: _closing, dueDay: _due, creditLimit: limit == 0 ? null : limit);
    } else {
      await repo.updateCard(editing.id, name: name, closingDay: _closing, dueDay: _due, creditLimit: limit == 0 ? null : limit);
      id = editing.id;
    }
    if (mounted) Navigator.pop(context, id);
  }

  /// A card with purchases or payments can't go (they'd lose it): archiving it hides it instead.
  Future<void> _delete(FinCard card) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    if (!await confirm(context, message: t.finDeleteCard(card.name), confirmLabel: t.actionDelete)) return;
    if (await repo.deleteCard(card.id)) {
      if (mounted) Navigator.pop(context);
      return;
    }
    if (!mounted || !await confirm(context, message: t.finCardDeleteBlocked, confirmLabel: t.finArchive)) return;
    await repo.archiveCard(card.id, archived: true);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget day(String label, int value, ValueChanged<int> onChanged) => Expanded(
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
        onChanged: (v) => setState(() => onChanged(v ?? value)),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(
          title: widget.editing == null ? t.finNewCard : t.finEditCard,
          onSave: () => unawaited(_save()),
          onDelete: switch (widget.editing) {
            final card? => () => unawaited(_delete(card)),
            null => null,
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: widget.editing == null,
                decoration: InputDecoration(labelText: t.finCardName, isDense: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [day(t.finClosingDay, _closing, (v) => _closing = v), const SizedBox(width: 12), day(t.finDueDay, _due, (v) => _due = v)],
              ),
              const SizedBox(height: 12),
              MoneyField(controller: _limit, label: t.finCreditLimit, onSubmitted: () => unawaited(_save())),
            ],
          ),
        ),
      ],
    );
  }
}
