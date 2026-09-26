import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/filters.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';

class FilterForm {
  const FilterForm({required this.name, required this.rule});

  final String name;
  final FilterRule rule;
}

/// "Adicionar Filtro" / "Editar Filtro": name, Normal / Avançado tabs, the criteria and
/// "Prévia" with the matching tasks.
///
/// Editing, [onDelete] shows the bin: it asks and deletes, and the dialog closes when it did.
Future<FilterForm?> showFilterDialog(BuildContext context, {TaskFilter? editing, Future<bool> Function()? onDelete}) => showDialog<FilterForm>(
  context: context,
  builder: (_) => _FilterDialog(editing: editing, onDelete: onDelete),
);

/// Label of each value of a field, in the order they are offered. A date condition can also hold a
/// [FilterDateRange] ("Personalizado"), which [filterValueLabel] names.
Map<String, String> filterOptions(AppLocalizations t, Snapshot s, FilterField field) {
  final labels = Labels(t);
  return switch (field) {
    FilterField.list => {for (final l in s.activeLists) l.id: labels.listName(l)},
    FilterField.tag => {for (final tag in s.activeTags) tag.id: tag.name},
    FilterField.date => {for (final d in FilterDate.values) d.name: filterDateLabel(t, d)},
    FilterField.priority => {for (final p in Priority.values.reversed) '${p.code}': labels.priority(p)},
    FilterField.kind => {TaskKind.text.code: t.searchTypeTask, TaskKind.note.code: t.searchTypeNote},
  };
}

/// The text of one chosen value: "Hoje", a list name, "01/09/2026 - 30/09/2026"…
String? filterValueLabel(Map<String, String> options, String value) {
  final range = FilterDateRange.parse(value);
  return range == null ? options[value] : filterRangeLabel(range);
}

String filterRangeLabel(FilterDateRange r) => '${DateLabels.numeric(r.from)} - ${DateLabels.numeric(r.to)}';

String filterDateLabel(AppLocalizations t, FilterDate d) => switch (d) {
  FilterDate.overdue => t.filterDateOverdue,
  FilterDate.today => t.filterDateToday,
  FilterDate.tomorrow => t.filterDateTomorrow,
  FilterDate.thisWeek => t.filterDateThisWeek,
  FilterDate.nextWeek => t.filterDateNextWeek,
  FilterDate.thisMonth => t.filterDateThisMonth,
  FilterDate.nextMonth => t.filterDateNextMonth,
  FilterDate.noDate => t.filterDateNoDate,
};

String filterFieldLabel(AppLocalizations t, FilterField f) => switch (f) {
  FilterField.list => t.filterFieldList,
  FilterField.tag => t.filterFieldTag,
  FilterField.date => t.filterFieldDate,
  FilterField.priority => t.filterFieldPriority,
  FilterField.kind => t.filterFieldType,
};

/// An editable condition of the advanced mode.
class _Condition {
  _Condition(this.field, [Set<String>? values, this.negate = false]) : values = values ?? {};

  FilterField field;
  Set<String> values;
  bool negate;

  FilterCondition get frozen => FilterCondition(field: field, values: {...values}, negate: negate);
}

class _FilterDialog extends ConsumerStatefulWidget {
  const _FilterDialog({this.editing, this.onDelete});

  final TaskFilter? editing;
  final Future<bool> Function()? onDelete;

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  late final FilterRule _initial = widget.editing == null ? const FilterRule() : FilterRule.decode(widget.editing!.rule);
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _keyword = TextEditingController(text: _initial.keyword);
  late bool _advanced = _initial.advanced;
  late bool _any = _initial.any;

  /// Normal mode: one value set per field.
  late final Map<FilterField, Set<String>> _normal = {
    for (final f in FilterField.values) f: {for (final c in _initial.conditions.where((c) => c.field == f && !c.negate)) ...c.values},
  };

  /// Advanced mode: any number of conditions.
  late final List<_Condition> _conditions = [
    for (final c in _initial.conditions) _Condition(c.field, {...c.values}, c.negate),
  ];
  bool _preview = false;

  @override
  void dispose() {
    _name.dispose();
    _keyword.dispose();
    super.dispose();
  }

  FilterRule get _rule => _advanced
      ? FilterRule(advanced: true, any: _any, keyword: _keyword.text.trim(), conditions: [for (final c in _conditions) c.frozen])
      : FilterRule(
          keyword: _keyword.text.trim(),
          conditions: [
            for (final e in _normal.entries)
              if (e.value.isNotEmpty) FilterCondition(field: e.key, values: {...e.value}),
          ],
        );

  void _setAdvanced(bool advanced) {
    if (advanced == _advanced) return;
    setState(() {
      if (advanced) {
        _conditions
          ..clear()
          ..addAll([
            for (final e in _normal.entries)
              if (e.value.isNotEmpty) _Condition(e.key, {...e.value}),
          ]);
        if (_conditions.isEmpty) _conditions.add(_Condition(FilterField.list));
      } else {
        // Normal mode has no "não é" nor OU: keep what it can show.
        for (final f in FilterField.values) {
          _normal[f] = {for (final c in _conditions.where((c) => c.field == f && !c.negate)) ...c.values};
        }
        _any = false;
      }
      _advanced = advanced;
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, FilterForm(name: name, rule: _rule));
  }

  /// Multi-select dialog for the values of [field]. Dates end with "Personalizado", which asks for
  /// the first and last day.
  Future<void> _pickValues(Snapshot s, FilterField field, Set<String> values) async {
    final t = AppLocalizations.of(context);
    final options = filterOptions(t, s, field);
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        final selected = {...values};
        FilterDateRange? rangeOf(Set<String> values) => values.map(FilterDateRange.parse).nonNulls.firstOrNull;

        Future<void> pickRange(void Function(void Function()) setLocal) async {
          final current = rangeOf(selected);
          final today = startOfDay(ref.read(clockProvider).now());
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(today.year - 10),
            lastDate: DateTime(today.year + 10),
            initialDateRange: current == null ? null : DateTimeRange(start: current.from, end: current.to),
          );
          if (range == null) return;
          setLocal(() {
            selected
              ..removeWhere((v) => FilterDateRange.parse(v) != null)
              ..add(FilterDateRange(range.start, range.end).value);
          });
        }

        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(filterFieldLabel(t, field), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: 320,
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(dense: true, value: selected.isEmpty, title: Text(t.searchAll), onChanged: (_) => setLocal(selected.clear)),
                  for (final o in options.entries)
                    CheckboxListTile(
                      dense: true,
                      value: selected.contains(o.key),
                      title: Text(o.value, overflow: TextOverflow.ellipsis),
                      onChanged: (on) => setLocal(() => on == true ? selected.add(o.key) : selected.remove(o.key)),
                    ),
                  if (field == FilterField.date)
                    CheckboxListTile(
                      dense: true,
                      value: rangeOf(selected) != null,
                      title: Text(t.searchDateCustom),
                      subtitle: switch (rangeOf(selected)) {
                        final range? => Text(filterRangeLabel(range)),
                        null => null,
                      },
                      onChanged: (on) =>
                          on == true ? pickRange(setLocal) : setLocal(() => selected.removeWhere((v) => FilterDateRange.parse(v) != null)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text(t.actionOk)),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      setState(
        () => values
          ..clear()
          ..addAll(picked),
      );
    }
  }

  /// The button showing the chosen values ("Todas" when none).
  Widget _valuesButton(Snapshot s, FilterField field, Set<String> values) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final options = filterOptions(t, s, field);
    final text = values.isEmpty ? t.searchAll : [for (final v in values) ?filterValueLabel(options, v)].join(', ');
    return InkWell(
      onTap: () => _pickValues(s, field, values),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: TtText.body, color: values.isEmpty ? tt.textTertiary : tt.text),
              ),
            ),
            Icon(Icons.expand_more, size: 16, color: tt.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _labeled(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: TextStyle(color: context.tt.textSecondary)),
        ),
        Expanded(child: child),
      ],
    ),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: context.tt.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
  );

  List<Widget> _normalRows(AppLocalizations t, Snapshot s) => [
    for (final f in FilterField.values) _labeled(filterFieldLabel(t, f), _valuesButton(s, f, _normal[f]!)),
  ];

  List<Widget> _advancedRows(AppLocalizations t, Snapshot s) {
    final tt = context.tt;
    return [
      for (final (i, c) in _conditions.indexed) ...[
        if (i > 0)
          // One joiner for every condition, like TickTick's advanced mode: E or OU.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: tt.primary),
              onPressed: () => setState(() => _any = !_any),
              child: Text(_any ? t.filterOr : t.filterAnd, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          decoration: BoxDecoration(
            border: Border.all(color: tt.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              DropdownButton<FilterField>(
                value: c.field,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [for (final f in FilterField.values) DropdownMenuItem(value: f, child: Text(filterFieldLabel(t, f)))],
                onChanged: (f) => setState(() {
                  if (f == null || f == c.field) return;
                  c
                    ..field = f
                    ..values = {};
                }),
              ),
              const SizedBox(width: 8),
              DropdownButton<bool>(
                value: c.negate,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: false, child: Text(t.filterIs)),
                  DropdownMenuItem(value: true, child: Text(t.filterIsNot)),
                ],
                onChanged: (v) => setState(() => c.negate = v ?? false),
              ),
              const SizedBox(width: 8),
              Expanded(child: _valuesButton(s, c.field, c.values)),
              IconButton(
                tooltip: t.actionDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 16, color: tt.textTertiary),
                onPressed: () => setState(() => _conditions.remove(c)),
              ),
            ],
          ),
        ),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text(t.filterAddCondition),
          onPressed: () => setState(() => _conditions.add(_Condition(FilterField.list))),
        ),
      ),
    ];
  }

  Widget _previewList(AppLocalizations t, Snapshot s) {
    final tt = context.tt;
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final rule = _rule;
    final matches = s.tasks.where((task) => filterMatches(s, task, rule, startOfDay(now))).toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(color: tt.hover, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.filterPreviewCount(matches.length),
            style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w600, color: tt.textSecondary),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final task in matches)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      task.title.isEmpty ? t.untitled : task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: TtText.small, color: tt.text),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.editing == null ? t.filterAddTitle : t.filterEditTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: false, label: Text(t.filterNormal)),
              ButtonSegment(value: true, label: Text(t.filterAdvanced)),
            ],
            selected: {_advanced},
            onSelectionChanged: (v) => _setAdvanced(v.first),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: _fieldDecoration(t.filterName),
              ),
              const SizedBox(height: 14),
              if (_advanced) ..._advancedRows(t, s) else ..._normalRows(t, s),
              const SizedBox(height: 4),
              _labeled(
                t.filterKeyword,
                TextField(controller: _keyword, onChanged: (_) => setState(() {}), decoration: _fieldDecoration(t.filterKeywordHint)),
              ),
              if (_preview) _previewList(t, s),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _preview = !_preview),
          style: TextButton.styleFrom(foregroundColor: _preview ? tt.primary : tt.textSecondary),
          child: Text(t.filterPreview),
        ),
        const SizedBox(width: 24),
        if (widget.editing != null && widget.onDelete != null)
          IconButton(
            tooltip: t.actionDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () async {
              if (await widget.onDelete!() && context.mounted) Navigator.pop(context);
            },
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: _name.text.trim().isEmpty ? null : _submit, child: Text(t.actionSave)),
      ],
    );
  }
}
