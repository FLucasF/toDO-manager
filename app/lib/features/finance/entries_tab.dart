import 'dart:async';

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
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import 'entry_form.dart';
import 'finance_widgets.dart';

enum _Period { month, year, custom }

/// "Lançamentos": the period (month, year or custom days), its totals, filters by category, kind and
/// words, and the entries by day; a card's purchases come together under their invoice.
class EntriesTab extends ConsumerStatefulWidget {
  const EntriesTab({super.key});

  @override
  ConsumerState<EntriesTab> createState() => _EntriesTabState();
}

class _EntriesTabState extends ConsumerState<EntriesTab> {
  _Period _period = _Period.month;
  late DateTime _anchor = monthOf(ref.read(clockProvider).now());
  DateTimeRange? _custom;

  /// null = all; '' = "Sem categoria".
  String? _categoryId;
  FinKind? _kind;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ({DateTime from, DateTime to}) get _range => switch (_period) {
    _Period.month => (from: _anchor, to: DateTime(_anchor.year, _anchor.month + 1, 0)),
    _Period.year => (from: DateTime(_anchor.year), to: DateTime(_anchor.year, 12, 31)),
    _Period.custom => (from: startOfDay(_custom!.start), to: startOfDay(_custom!.end)),
  };

  void _step(int delta) =>
      setState(() => _anchor = _period == _Period.year ? DateTime(_anchor.year + delta) : DateTime(_anchor.year, _anchor.month + delta));

  Future<void> _choosePeriod(_Period period) async {
    if (period == _Period.custom) {
      final range = _range;
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(start: range.from, end: range.to),
      );
      if (picked == null) return;
      _custom = picked;
    }
    final today = ref.read(clockProvider).now();
    setState(() {
      if (period != _Period.custom && _period == _Period.custom) _anchor = monthOf(today);
      if (period == _Period.year) _anchor = DateTime(_anchor.year);
      _period = period;
    });
  }

  String _periodTitle(AppLocalizations t) {
    final range = _range;
    return switch (_period) {
      _Period.month => DateLabels(t).monthTitle(_anchor),
      _Period.year => '${_anchor.year}',
      _Period.custom => '${DateLabels.numeric(range.from)} - ${DateLabels.numeric(range.to)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final range = _range;
    final inPeriod = filterEntries(s, EntryFilter(from: range.from, to: range.to));
    final shown = filterEntries(
      s,
      EntryFilter(from: range.from, to: range.to, categoryIds: _categoryId == null ? const {} : {_categoryId!}, kind: _kind, text: _search.text),
    );
    final totals = totalsOf(inPeriod);
    final groups = groupEntries(s, shown);
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());

    final periodBar = Row(
      children: [
        if (_period != _Period.custom) IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _step(-1)),
        PopupMenuButton<_Period>(
          tooltip: '',
          onSelected: (p) => unawaited(_choosePeriod(p)),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(value: _Period.month, checked: _period == _Period.month, child: Text(t.finPeriodMonth)),
            CheckedPopupMenuItem(value: _Period.year, checked: _period == _Period.year, child: Text(t.finPeriodYear)),
            CheckedPopupMenuItem(value: _Period.custom, checked: _period == _Period.custom, child: Text(t.searchDateCustom)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _periodTitle(t),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tt.text),
                ),
                Icon(Icons.expand_more, size: 18, color: tt.textTertiary),
              ],
            ),
          ),
        ),
        if (_period != _Period.custom) IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _step(1)),
      ],
    );

    Widget summary(String label, int cents, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(cents),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );

    final categories = [...s.categoriesOf(FinKind.expense), ...s.categoriesOf(FinKind.income)];
    final filters = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterChip<String?>(
          label: _categoryId == null ? t.finAllCategories : (_categoryId!.isEmpty ? t.finNoCategory : categoryName(t, s.categoryById[_categoryId])),
          active: _categoryId != null,
          value: _categoryId,
          options: {null: t.finAllCategories, '': t.finNoCategory, for (final c in categories) c.id: '${c.icon} ${c.name}'.trim()},
          onSelected: (v) => setState(() => _categoryId = v),
        ),
        _FilterChip<FinKind?>(
          label: switch (_kind) {
            null => t.finAllKinds,
            FinKind.income => t.finIncomes,
            FinKind.expense => t.finExpenses,
          },
          active: _kind != null,
          value: _kind,
          options: {null: t.finAllKinds, FinKind.income: t.finIncomes, FinKind.expense: t.finExpenses},
          onSelected: (v) => setState(() => _kind = v),
        ),
        SizedBox(
          width: narrow ? double.infinity : 220,
          height: 36,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t.finSearchHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              filled: true,
              fillColor: tt.fieldFill,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        periodBar,
        const SizedBox(height: 4),
        Row(
          children: [
            summary(t.finIncomes, totals.income, tt.palette.green),
            const SizedBox(width: 8),
            summary(t.finExpenses, totals.expense, tt.overdue),
            const SizedBox(width: 8),
            summary(t.finBalance, totals.balance, totals.balance < 0 ? tt.overdue : tt.text),
          ],
        ),
        const SizedBox(height: 12),
        filters,
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              t.finEntriesEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final g in groups) ...[_GroupHeader(group: g, today: today), for (final e in g.entries) _EntryRow(entry: e, snapshot: s)],
      ],
    );
  }
}

/// A chip that opens a menu of [options]. The menu works with positions: a null value ("all")
/// would look like closing it without choosing.
class _FilterChip<T> extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.value, required this.options, required this.onSelected});

  final String label;
  final bool active;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final choices = options.entries.toList();
    return PopupMenuButton<int>(
      tooltip: '',
      onSelected: (i) => onSelected(choices[i].key),
      itemBuilder: (_) => [
        for (final (i, o) in choices.indexed)
          CheckedPopupMenuItem<int>(
            value: i,
            checked: o.key == value,
            child: Text(o.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: active ? tt.primary.withValues(alpha: 0.12) : tt.fieldFill, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: TtText.small, color: active ? tt.primary : tt.textSecondary),
              ),
            ),
            Icon(Icons.expand_more, size: 16, color: active ? tt.primary : tt.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// "Quinta-feira, 24 setembro" with the day's balance, or the card invoice with its total.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group, required this.today});

  final EntryGroup group;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final card = group.card;
    final totals = group.totals;
    final title = card == null ? dates.dayHeader(group.day, today) : t.finInvoiceOf(card.name, DateLabels.numeric(group.day, withYear: false));
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Row(
        children: [
          if (card != null) ...[Icon(Icons.credit_card, size: 15, color: tt.textTertiary), const SizedBox(width: 6)],
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
            ),
          ),
          Text(
            formatMoney(totals.balance),
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.snapshot});

  final FinEntry entry;
  final FinanceSnapshot snapshot;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(financeRepositoryProvider);
    var ids = [entry.id];
    final group = entry.installmentGroup;
    if (group != null) {
      final all = await repo.installmentIds(group);
      if (!context.mounted) return;
      final every = await showDialog<bool>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(t.finDeleteInstallments),
          children: [
            SimpleDialogOption(onPressed: () => Navigator.pop(context, false), child: Text(t.finDeleteOneInstallment)),
            SimpleDialogOption(onPressed: () => Navigator.pop(context, true), child: Text(t.finDeleteAllInstallments(all.length))),
          ],
        ),
      );
      if (every == null) return;
      if (every) ids = all;
    }
    await repo.deleteEntries(ids);
    if (context.mounted) showToast(context, t.finEntryDeleted, undo: () => repo.restoreEntries(ids), redo: () => repo.deleteEntries(ids));
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
        PopupMenuItem(value: 'copy', height: 36, child: Text(t.finDuplicate)),
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
        await showEntryForm(context, editing: entry);
      case 'copy':
        await showEntryForm(context, copy: entry);
      case 'delete':
        await _delete(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final category = entry.categoryId == null ? null : snapshot.categoryById[entry.categoryId];
    final title = entry.description.isNotEmpty ? entry.description : categoryName(t, category);
    final details = [
      if (entry.description.isNotEmpty) categoryName(t, category),
      if (entry.installmentIndex case final i?) '$i/${entry.installmentCount}',
      // A card purchase sits under its invoice: its own day goes here.
      if (entry.cardId != null) DateLabels.numeric(finDay(entry.date), withYear: false),
    ];
    return GestureDetector(
      onSecondaryTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      onLongPressStart: (d) => unawaited(_menu(context, ref, d.globalPosition)),
      child: InkWell(
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tt.text, fontSize: TtText.body),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                signedMoney(entry.kind, entry.amount),
                style: TextStyle(color: finKindColor(context, entry.kind), fontSize: TtText.body, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
