import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/finance/cards.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/money.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import 'entry_form.dart';
import 'finance_widgets.dart';

/// "Cartões": the cards as chips; the chosen one shows its invoices month by month (status, closing
/// and due days, total, paid, left), its purchases and payments, and "Pagar fatura".
class CardsTab extends ConsumerStatefulWidget {
  const CardsTab({super.key});

  @override
  ConsumerState<CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends ConsumerState<CardsTab> {
  String? _cardId;
  DateTime? _month;
  bool _archived = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final cards = [
      for (final c in s.cards)
        if ((c.archivedAt != null) == _archived) c,
    ];
    final card = cards.where((c) => c.id == _cardId).firstOrNull ?? cards.firstOrNull;
    final hasArchived = s.cards.any((c) => c.archivedAt != null);

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in cards)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FinChip(
                icon: Icons.credit_card,
                label: c.name,
                selected: c.id == card?.id,
                onTap: () => setState(() {
                  _cardId = c.id;
                  _month = null;
                }),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: Text(t.finNewCard),
            onPressed: () async {
              final id = await showCardForm(context);
              if (id != null && mounted) setState(() => _cardId = id);
            },
          ),
          if (hasArchived || _archived) ...[
            const SizedBox(width: 8),
            FinChip(
              label: t.finArchivedCards,
              selected: _archived,
              onTap: () => setState(() {
                _archived = !_archived;
                _cardId = null;
                _month = null;
              }),
            ),
          ],
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 8, narrow ? 12 : 20, 32),
      children: [
        chips,
        if (card == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              t.finNoCards,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          )
        else
          _CardView(
            card: card,
            snapshot: s,
            today: today,
            month: _month ?? currentInvoiceMonth(card, today),
            onMonth: (m) => setState(() => _month = m),
          ),
      ],
    );
  }
}

class _CardView extends ConsumerWidget {
  const _CardView({required this.card, required this.snapshot, required this.today, required this.month, required this.onMonth});

  final FinCard card;
  final FinanceSnapshot snapshot;
  final DateTime today;
  final DateTime month;
  final ValueChanged<DateTime> onMonth;

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    final box = context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(Offset(box.size.width - 20, 40));
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        PopupMenuItem(value: 'archive', height: 36, child: Text(card.archivedAt == null ? t.finArchive : t.finUnarchive)),
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Text(t.actionDelete, style: TextStyle(color: context.tt.overdue)),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'edit':
        await showCardForm(context, editing: card);
      case 'archive':
        await repo.archiveCard(card.id, archived: card.archivedAt == null);
      case 'delete':
        if (!await confirm(context, message: t.finDeleteCard(card.name), confirmLabel: t.actionDelete)) return;
        final deleted = await repo.deleteCard(card.id);
        if (!deleted && context.mounted) showToast(context, t.finCardDeleteBlocked);
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref, InvoiceSummary invoice) async {
    final paid = await showFinanceDialog<bool>(
      context,
      builder: (_) => _PaymentForm(invoice: invoice, today: today),
    );
    if (paid == true && context.mounted) showToast(context, AppLocalizations.of(context).toastSaved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final invoice = invoiceOf(snapshot, card, month, today);
    final limit = card.creditLimit;
    final used = cardUsed(snapshot, card);
    final (statusLabel, statusColor) = switch (invoice.status) {
      InvoiceStatus.open => (t.finInvoiceOpen, tt.primary),
      InvoiceStatus.closed => (t.finInvoiceClosed, tt.palette.priorityMedium),
      InvoiceStatus.paid => (t.finInvoicePaid, tt.palette.green),
      InvoiceStatus.overdue => (t.finInvoiceOverdue, tt.overdue),
      InvoiceStatus.empty => (t.finInvoiceEmpty, tt.textTertiary),
    };

    Widget amount(String label, int cents, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(cents),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? tt.text),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                  Text(
                    t.finCardDays(card.closingDay, card.dueDay),
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.more_horiz, color: tt.textSecondary),
                onPressed: () => unawaited(_menu(context, ref)),
              ),
            ),
          ],
        ),
        if (limit != null) ...[
          const SizedBox(height: 8),
          Text(
            t.finCardUsed(formatMoney(used), formatMoney(limit)),
            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: limit == 0 ? 1 : (used / limit).clamp(0, 1).toDouble(),
              minHeight: 5,
              color: used > limit ? tt.overdue : tt.primary,
              backgroundColor: tt.fieldFill,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // The invoice: ‹ Fatura de Outubro 2026 › and its status.
        Row(
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onMonth(DateTime(month.year, month.month - 1))),
            Expanded(
              child: Text(
                t.finInvoiceTitle(dates.monthTitle(month)),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tt.text),
              ),
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onMonth(DateTime(month.year, month.month + 1))),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: TtText.small, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.finInvoiceDates(DateLabels.numeric(invoice.closing, withYear: false), DateLabels.numeric(invoice.due, withYear: false)),
                      style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  amount(t.finInvoiceTotal, invoice.total),
                  amount(t.finInvoicePaidAmount, invoice.paid, color: tt.palette.green),
                  amount(t.finInvoiceRemaining, invoice.remaining < 0 ? 0 : invoice.remaining, color: invoice.remaining > 0 ? tt.overdue : null),
                ],
              ),
              if (invoice.remaining > 0) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(t.finPayInvoice),
                    onPressed: () => unawaited(_pay(context, ref, invoice)),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (invoice.entries.isNotEmpty) _SectionTitle(t.finPurchases),
        for (final e in invoice.entries) _PurchaseRow(entry: e, snapshot: snapshot),
        if (invoice.payments.isNotEmpty) _SectionTitle(t.finPayments),
        for (final p in invoice.payments)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(Icons.check_circle_outline, color: tt.palette.green),
            title: Text(formatMoney(p.amount), style: TextStyle(color: tt.text)),
            subtitle: Text(DateLabels.numeric(finDay(p.date)), style: TextStyle(color: tt.textTertiary)),
            trailing: IconButton(
              tooltip: t.actionDelete,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 4),
    child: Text(
      text,
      style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: context.tt.textSecondary),
    ),
  );
}

/// A purchase of the invoice: a click edits it.
class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.entry, required this.snapshot});

  final FinEntry entry;
  final FinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final category = entry.categoryId == null ? null : snapshot.categoryById[entry.categoryId];
    final details = [
      DateLabels.numeric(finDay(entry.date), withYear: false),
      if (entry.installmentIndex case final i?) '$i/${entry.installmentCount}',
      if (entry.description.isNotEmpty) categoryName(t, category),
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => unawaited(showEntryForm(context, editing: entry)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            CategoryIcon(category: category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description.isNotEmpty ? entry.description : categoryName(t, category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tt.text),
                  ),
                  Text(
                    details.join(' · '),
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              signedMoney(entry.kind, entry.amount),
              style: TextStyle(color: finKindColor(context, entry.kind), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Pagar fatura": the amount (what is left, to begin with) and the day.
class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.invoice, required this.today});

  final InvoiceSummary invoice;
  final DateTime today;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  late final _amount = TextEditingController(text: formatMoney(widget.invoice.remaining, symbol: false));
  late DateTime _date = widget.today;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return;
    await ref
        .read(financeRepositoryProvider)
        .payInvoice(cardId: widget.invoice.card.id, invoiceMonth: widget.invoice.month, amount: amount, date: _date);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: t.finPayInvoice, onSave: () => unawaited(_save())),
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
        FormHeader(title: widget.editing == null ? t.finNewCard : t.finEditCard, onSave: () => unawaited(_save())),
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
