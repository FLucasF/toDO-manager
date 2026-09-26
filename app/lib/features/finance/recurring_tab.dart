import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/finance_enums.dart';
import '../../domain/finance/money.dart';
import '../../domain/finance/recurring.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/shell_widgets.dart';
import 'finance_widgets.dart';

/// "Contas fixas": the month's due days laid out as the Agenda (each bill with its status: paid, to
/// pay, late) and, on the current month, the late ones of earlier months on top. "Pagar" (or
/// "Receber") creates the entry; ↶ undoes it. The bills themselves are in the left panel.
class RecurringBody extends ConsumerWidget {
  const RecurringBody({super.key, required this.month, required this.today});

  final DateTime month;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final monthItems = occurrences(s, month, DateTime(month.year, month.month + 1, 0), today);
    final late = month == monthOf(today) ? overdueOccurrences(s, today).where((o) => o.due.isBefore(month)).toList() : const <Occurrence>[];
    final toPay = monthItems
        .where((o) => o.status != OccurrenceStatus.paid && o.recurring.kind == FinKind.expense)
        .fold(0, (sum, o) => sum + o.recurring.amount);
    final paid = monthItems
        .where((o) => o.status == OccurrenceStatus.paid && o.recurring.kind == FinKind.expense)
        .fold(0, (sum, o) => sum + (o.entry?.amount ?? 0));
    final toReceive = monthItems
        .where((o) => o.status != OccurrenceStatus.paid && o.recurring.kind == FinKind.income)
        .fold(0, (sum, o) => sum + o.recurring.amount);

    List<Widget> blocks(List<Occurrence> items) {
      final byDay = <DateTime, List<Occurrence>>{};
      for (final o in items) {
        byDay.putIfAbsent(o.due, () => []).add(o);
      }
      final days = byDay.keys.toList()..sort();
      return [
        for (final (i, day) in days.indexed) ...[
          if (i > 0) Divider(height: 1, color: tt.divider),
          AgendaBlock(
            day: day,
            today: today,
            children: [for (final o in byDay[day]!) _OccurrenceLine(occurrence: o, snapshot: s)],
          ),
        ],
      ];
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        FigureStrip(
          figures: [
            (label: t.finInvoiceRemaining, value: formatMoney(toPay), color: toPay > 0 ? tt.overdue : null, hint: null),
            (label: t.finInvoicePaidAmount, value: formatMoney(paid), color: tt.palette.green, hint: null),
            if (toReceive > 0) (label: t.finToReceive, value: formatMoney(toReceive), color: tt.palette.green, hint: null),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: tt.divider),
        if (s.recurrings.every((r) => r.archivedAt != null))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              t.finNoRecurring,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        if (late.isNotEmpty) ...[BodyHeading(t.finOverdueBills, color: tt.overdue), ...blocks(late), Divider(height: 1, color: tt.divider)],
        ...blocks(monthItems),
      ],
    );
  }
}

/// "Todo dia 10", "Todo ano em 10/03".
String recurringWhen(AppLocalizations t, FinRecurring r) => r.frequency == FinFrequency.monthly
    ? t.finEveryMonthOn(r.day)
    : t.finEveryYearOn('${r.day.toString().padLeft(2, '0')}/${(r.month ?? 1).toString().padLeft(2, '0')}');

/// One due day of a bill: the status' dot (green paid, red late, grey to pay), "Pago em 24/09" or the
/// category, the bill, the amount and "Pagar" (or ↶ when paid). A click edits the bill.
class _OccurrenceLine extends ConsumerWidget {
  const _OccurrenceLine({required this.occurrence, required this.snapshot});

  final Occurrence occurrence;
  final FinanceSnapshot snapshot;

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final entry = occurrence.entry;
    if (entry == null) return;
    final repo = ref.read(financeRepositoryProvider);
    await repo.deleteEntries([entry.id]);
    if (context.mounted) {
      showToast(context, t.finPaymentUndone, undo: () => repo.restoreEntries([entry.id]), redo: () => repo.deleteEntries([entry.id]));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final r = occurrence.recurring;
    final category = r.categoryId == null ? null : snapshot.categoryById[r.categoryId];
    final entry = occurrence.entry;
    final color = switch (occurrence.status) {
      OccurrenceStatus.paid => tt.palette.green,
      OccurrenceStatus.overdue => tt.overdue,
      OccurrenceStatus.pending => categoryColor(context, snapshot, category),
    };
    return AgendaLine(
      color: color,
      secondary: switch (occurrence.status) {
        OccurrenceStatus.paid => t.finPaidOn(DateLabels.numeric(finDay(entry!.date), withYear: false)),
        OccurrenceStatus.overdue => t.finInvoiceOverdue,
        OccurrenceStatus.pending => '${category?.icon ?? ''} ${categoryName(t, category)}'.trim(),
      },
      title: r.description,
      struck: occurrence.status == OccurrenceStatus.paid,
      faded: occurrence.status == OccurrenceStatus.paid,
      onTap: () => unawaited(showRecurringForm(context, editing: r)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            signedMoney(r.kind, entry?.amount ?? r.amount),
            style: TextStyle(color: finKindColor(context, r.kind), fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (entry == null)
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: tt.primary.withValues(alpha: 0.15),
                foregroundColor: tt.primary,
              ),
              onPressed: () => unawaited(showConfirmPayment(context, occurrence)),
              child: Text(r.kind == FinKind.income ? t.finConfirmReceived : t.finConfirmPaid),
            )
          else
            IconButton(
              tooltip: t.finUndoPayment,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.undo, size: 18, color: tt.textTertiary),
              onPressed: () => unawaited(_undo(context, ref)),
            ),
        ],
      ),
    );
  }
}

/// Confirms one occurrence: the amount (the bill's, to begin with) and the day it was paid become an
/// entry of the bill's category (and card).
Future<void> showConfirmPayment(BuildContext context, Occurrence occurrence) =>
    showFinanceDialog<void>(context, builder: (_) => _ConfirmForm(occurrence: occurrence));

class _ConfirmForm extends ConsumerStatefulWidget {
  const _ConfirmForm({required this.occurrence});

  final Occurrence occurrence;

  @override
  ConsumerState<_ConfirmForm> createState() => _ConfirmFormState();
}

class _ConfirmFormState extends ConsumerState<_ConfirmForm> {
  late final _amount = TextEditingController(text: formatMoney(widget.occurrence.recurring.amount, symbol: false));
  late DateTime _date = startOfDay(ref.read(clockProvider).now());

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return;
    final r = widget.occurrence.recurring;
    await ref
        .read(financeRepositoryProvider)
        .addEntry(
          kind: r.kind,
          amount: amount,
          date: _date,
          description: r.description,
          categoryId: r.categoryId,
          cardId: r.kind == FinKind.expense ? r.cardId : null,
          recurringId: r.id,
          recurringDue: widget.occurrence.due,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final r = widget.occurrence.recurring;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: r.kind == FinKind.income ? t.finConfirmReceived : t.finConfirmPaid, onSave: () => unawaited(_save())),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${r.description} · ${t.finDueOn(DateLabels.numeric(widget.occurrence.due))}', style: TextStyle(color: tt.textSecondary)),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: t.finAmount, autofocus: true, onSubmitted: () => unawaited(_save())),
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

/// "Nova conta fixa" / "Editar conta fixa".
Future<void> showRecurringForm(BuildContext context, {FinRecurring? editing}) =>
    showFinanceDialog<void>(context, builder: (_) => _RecurringForm(editing: editing));

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({this.editing});

  final FinRecurring? editing;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  late final FinRecurring? _r = widget.editing;
  late FinKind _kind = _r?.kind ?? FinKind.expense;
  late final _description = TextEditingController(text: _r?.description ?? '');
  late final _amount = TextEditingController(text: _r == null ? '' : formatMoney(_r.amount, symbol: false));
  late FinFrequency _frequency = _r?.frequency ?? FinFrequency.monthly;
  late int _day = _r?.day ?? ref.read(clockProvider).now().day;
  late int _month = _r?.month ?? ref.read(clockProvider).now().month;
  late String? _categoryId = _r?.categoryId;
  late String? _cardId = _r?.cardId;
  // From the first day of this month: this month's due day shows up to be confirmed.
  late DateTime _start = _r == null ? monthOf(ref.read(clockProvider).now()) : finDay(_r.startDate);
  late DateTime? _end = _r?.endDate == null ? null : finDay(_r!.endDate!);

  /// null = no reminder.
  late int? _remind = _r == null ? 0 : _r.remindDaysBefore;
  bool _showError = false;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseMoney(_amount.text);
    final description = _description.text.trim();
    if (amount == null || amount <= 0 || description.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final repo = ref.read(financeRepositoryProvider);
    final row = FinRecurringsCompanion(
      kind: Value(_kind),
      description: Value(description),
      amount: Value(amount),
      categoryId: Value(_categoryId),
      cardId: Value(_kind == FinKind.expense ? _cardId : null),
      frequency: Value(_frequency),
      day: Value(_day),
      month: Value(_frequency == FinFrequency.yearly ? _month : null),
      startDate: Value(storedDay(_start)),
      endDate: Value(_end == null ? null : storedDay(_end!)),
      remindDaysBefore: Value(_remind),
    );
    final editing = widget.editing;
    if (editing == null) {
      await repo.createRecurring(row);
    } else {
      await repo.updateRecurring(editing.id, row);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<DateTime?> _pick(DateTime initial) =>
      showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final categories = s.categoriesOf(_kind);
    final categoryId = categories.any((c) => c.id == _categoryId) ? _categoryId : null;
    final cards = [
      for (final c in s.cards)
        if (c.archivedAt == null || c.id == _cardId) c,
    ];
    final cardId = cards.any((c) => c.id == _cardId) ? _cardId : null;
    final months = [for (var m = 1; m <= 12; m++) DateLabels(t).monthLong(DateTime(2026, m))];

    Widget dateTile(String label, String value, VoidCallback onTap, {Widget? trailing}) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.event_outlined, color: tt.textSecondary),
      title: Text(
        label,
        style: TextStyle(color: tt.textSecondary, fontSize: TtText.small),
      ),
      subtitle: Text(value, style: TextStyle(color: tt.text)),
      trailing: trailing,
      onTap: onTap,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormHeader(title: widget.editing == null ? t.finNewRecurring : t.finEditRecurring, onSave: () => unawaited(_save())),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              SegmentedButton<FinKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: FinKind.expense, label: Text(t.finExpense)),
                  ButtonSegment(value: FinKind.income, label: Text(t.finIncome)),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                autofocus: widget.editing == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: t.finDescription, hintText: t.finRecurringHint, isDense: true),
              ),
              const SizedBox(height: 8),
              MoneyField(controller: _amount, label: t.finAmount, onChanged: (_) => setState(() => _showError = false)),
              if (_showError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    t.finRecurringInvalid,
                    style: TextStyle(color: tt.overdue, fontSize: TtText.small),
                  ),
                ),
              const SizedBox(height: 12),
              SegmentedButton<FinFrequency>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: FinFrequency.monthly, label: Text(t.finMonthly)),
                  ButtonSegment(value: FinFrequency.yearly, label: Text(t.finYearly)),
                ],
                selected: {_frequency},
                onSelectionChanged: (v) => setState(() => _frequency = v.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _day,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.finDueDay, isDense: true),
                      items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                      onChanged: (v) => setState(() => _day = v ?? _day),
                    ),
                  ),
                  if (_frequency == FinFrequency.yearly) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _month,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t.finPeriodMonth, isDense: true),
                        items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(months[m - 1]))],
                        onChanged: (v) => setState(() => _month = v ?? _month),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.finCategory, isDense: true),
                items: [
                  DropdownMenuItem(value: null, child: Text(t.finNoCategory)),
                  for (final c in categories) DropdownMenuItem(value: c.id, child: Text('${c.icon} ${c.name}'.trim())),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              if (_kind == FinKind.expense && cards.isNotEmpty) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: cardId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t.finCard, isDense: true),
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.finNoCard)),
                    for (final c in cards) DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _cardId = v),
                ),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _remind,
                isExpanded: true,
                decoration: InputDecoration(labelText: t.finReminder, isDense: true),
                items: [
                  DropdownMenuItem(value: null, child: Text(t.finNoReminder)),
                  DropdownMenuItem(value: 0, child: Text(t.finRemindOnDay)),
                  for (final d in const [1, 3, 7]) DropdownMenuItem(value: d, child: Text(t.finRemindDaysBefore(d))),
                ],
                onChanged: (v) => setState(() => _remind = v),
              ),
              dateTile(t.finStartsOn, DateLabels.numeric(_start), () async {
                final picked = await _pick(_start);
                if (picked != null) setState(() => _start = picked);
              }),
              dateTile(
                t.finEndsOn,
                _end == null ? t.finNoEnd : DateLabels.numeric(_end!),
                () async {
                  final picked = await _pick(_end ?? _start);
                  if (picked != null) setState(() => _end = picked);
                },
                trailing: _end == null
                    ? null
                    : IconButton(tooltip: t.finNoEnd, icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _end = null)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
