import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/enums.dart';
import '../../domain/filters.dart';
import '../../domain/search.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_row.dart';

/// Search page (`#s`): "Procurar por" with the editable term, ✕, the filter chips
/// Listas · Tag · Data · Prioridade · Tipo · Status and the results; the detail opens on the right.
class SearchPane extends ConsumerStatefulWidget {
  const SearchPane({super.key, required this.initialQuery, required this.selectedTaskId, this.isNarrow = false});

  final String initialQuery;
  final String? selectedTaskId;
  final bool isNarrow;

  @override
  ConsumerState<SearchPane> createState() => _SearchPaneState();
}

class _SearchPaneState extends ConsumerState<SearchPane> {
  late final _query = TextEditingController(text: widget.initialQuery);
  Set<String> _lists = {};
  Set<String> _tags = {};
  Set<Priority> _priorities = {};
  Set<TaskKind> _kinds = {};
  TaskStatus? _status;

  /// "Pesquisar em Arquivados".
  bool _archived = false;
  SearchDatePreset _date = SearchDatePreset.all;
  DateTimeRange? _custom;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  SearchFilters _filters(DateTime today) {
    final range = _date == SearchDatePreset.custom
        ? (_custom == null ? null : (from: _custom!.start, to: _custom!.end))
        : searchDateRange(_date, today);
    return SearchFilters(
      listIds: _lists,
      tagIds: _tags,
      priorities: _priorities,
      kinds: _kinds,
      statuses: _status == null ? const {TaskStatus.open, TaskStatus.completed, TaskStatus.wontDo} : {_status!},
      from: range?.from,
      to: range?.to,
      archived: _archived,
    );
  }

  /// "Salvar como filtro": the term and the chips become a filter in the sidebar. Filters only
  /// hold open tasks, so the status chip and the past date presets are left out.
  Future<void> _saveAsFilter(DateTime today) async {
    final t = AppLocalizations.of(context);
    final name = await promptText(context, title: t.filterSaveAs, initial: _query.text.trim(), hint: t.filterName);
    if (name == null || name.trim().isEmpty || !mounted) return;
    final date = switch (_date) {
      SearchDatePreset.thisWeek => FilterDate.thisWeek,
      SearchDatePreset.nextWeek => FilterDate.nextWeek,
      SearchDatePreset.thisMonth => FilterDate.thisMonth,
      _ => null,
    };
    final id = await ref.read(repositoryProvider).createFilter(name, FilterRule.fromSearch(_query.text, _filters(today), date: date));
    if (!mounted) return;
    showToast(context, t.filterSaved(name.trim()));
    context.go(Routes.of(FilterScope(id)));
  }

  void _open(String taskId) => context.go(Uri(path: Routes.search, queryParameters: {'q': _query.text.trim(), 'task': taskId}).toString());

  /// A chip opening a menu; [active] fills it with the primary color.
  Widget _chip({
    required String label,
    required bool active,
    required List<PopupMenuEntry<Object>> Function() items,
    required void Function(Object) onSelected,
  }) {
    final tt = context.tt;
    return PopupMenuButton<Object>(
      tooltip: '',
      itemBuilder: (_) => items(),
      onSelected: onSelected,
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? tt.primary.withValues(alpha: 0.15) : tt.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? tt.primary : tt.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.small, color: active ? tt.primary : tt.textSecondary),
            ),
            Icon(Icons.expand_more, size: 14, color: active ? tt.primary : tt.textTertiary),
          ],
        ),
      ),
    );
  }

  /// Multi-select menu entries with an "Todas" entry that clears the selection.
  List<PopupMenuEntry<Object>> _multi<T extends Object>(AppLocalizations t, Map<T, String> options, Set<T> selected) => [
    CheckedPopupMenuItem<Object>(value: const _All(), checked: selected.isEmpty, child: Text(t.searchAll)),
    for (final o in options.entries) CheckedPopupMenuItem<Object>(value: o.key, checked: selected.contains(o.key), child: Text(o.value)),
  ];

  Set<T> _toggle<T>(Set<T> set, Object value) => value is _All ? {} : (set.contains(value) ? ({...set}..remove(value)) : {...set, value as T});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final hits = searchTasks(s, _query.text, filters: _filters(today));
    final thisWeek = searchDateRange(SearchDatePreset.thisWeek, today)!;
    final dateOptions = {
      SearchDatePreset.all: t.searchDateAll,
      SearchDatePreset.thisWeek: t.searchDateThisWeek(
        '${thisWeek.from.day} ${dates.monthShort(thisWeek.from)} - ${thisWeek.to.day} ${dates.monthShort(thisWeek.to)}',
      ),
      SearchDatePreset.nextWeek: t.searchDateNextWeek,
      SearchDatePreset.lastWeek: t.searchDateLastWeek,
      SearchDatePreset.thisMonth: t.searchDateThisMonth,
      SearchDatePreset.lastMonth: t.searchDateLastMonth,
      SearchDatePreset.custom: t.searchDateCustom,
    };
    final statusOptions = {
      TaskStatus.open: t.searchStatusOpen,
      TaskStatus.completed: t.searchStatusCompleted,
      TaskStatus.wontDo: t.searchStatusWontDo,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      '${t.searchLookFor} ',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tt.text),
                    ),
                    // The term is editable in place, with the pencil right after it ("Procurar por modelo ✎").
                    Flexible(
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 40),
                          child: TextField(
                            controller: _query,
                            autofocus: widget.initialQuery.isEmpty,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tt.primary),
                            decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, contentPadding: EdgeInsets.zero),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.edit_outlined, size: 16, color: tt.textTertiary),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_outlined, size: 16),
                label: Text(t.filterSaveAs),
                onPressed: () => _saveAsFilter(today),
              ),
              IconButton(
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: () => context.go(Routes.backFromSearch),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            children: [
              _chip(
                label: t.searchFilterLists,
                active: _lists.isNotEmpty,
                items: () => _multi(t, {for (final l in s.activeLists) l.id: labels.listName(l)}, _lists),
                onSelected: (v) => setState(() => _lists = _toggle(_lists, v)),
              ),
              _chip(
                label: t.searchFilterTag,
                active: _tags.isNotEmpty,
                items: () => _multi(t, {for (final tag in s.activeTags) tag.id: tag.name}, _tags),
                onSelected: (v) => setState(() => _tags = _toggle(_tags, v)),
              ),
              _chip(
                label: _date == SearchDatePreset.all ? t.searchFilterDate : dateOptions[_date]!,
                active: _date != SearchDatePreset.all,
                items: () => [
                  for (final o in dateOptions.entries) CheckedPopupMenuItem<Object>(value: o.key, checked: _date == o.key, child: Text(o.value)),
                ],
                onSelected: (v) async {
                  final preset = v as SearchDatePreset;
                  if (preset == SearchDatePreset.custom) {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(today.year - 10),
                      lastDate: DateTime(today.year + 10),
                    );
                    if (range == null) return;
                    _custom = range;
                  }
                  setState(() => _date = preset);
                },
              ),
              _chip(
                label: t.searchFilterPriority,
                active: _priorities.isNotEmpty,
                items: () => _multi(t, {for (final p in Priority.values.reversed) p: labels.priority(p)}, _priorities),
                onSelected: (v) => setState(() => _priorities = _toggle(_priorities, v)),
              ),
              _chip(
                label: t.searchFilterType,
                active: _kinds.isNotEmpty,
                items: () => _multi(t, {
                  TaskKind.text: t.searchTypeTask,
                  TaskKind.note: t.searchTypeNote,
                }, _kinds.contains(TaskKind.text) ? ({..._kinds}..remove(TaskKind.checklist)) : _kinds),
                // "Tarefa" covers checklists too.
                onSelected: (v) => setState(() {
                  final next = _toggle(_kinds.difference({TaskKind.checklist}), v);
                  _kinds = next.contains(TaskKind.text) ? {...next, TaskKind.checklist} : next;
                }),
              ),
              _chip(
                label: _status == null ? t.searchFilterStatus : statusOptions[_status]!,
                active: _status != null,
                items: () => [
                  CheckedPopupMenuItem<Object>(value: const _All(), checked: _status == null, child: Text(t.searchAll)),
                  for (final o in statusOptions.entries) CheckedPopupMenuItem<Object>(value: o.key, checked: _status == o.key, child: Text(o.value)),
                ],
                onSelected: (v) => setState(() => _status = v is TaskStatus ? v : null),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _archived ? t.searchArchivedCount(hits.length) : t.searchResultCount(hits.length),
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _archived = !_archived),
                child: Text(_archived ? t.searchActiveLists : t.searchInArchived, style: const TextStyle(fontSize: TtText.small)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            itemCount: hits.length,
            itemBuilder: (context, i) {
              final hit = hits[i];
              final task = hit.task;
              final list = s.listById[task.listId];
              final due = task.dueDate?.toLocal();
              return InkWell(
                onTap: () => _open(task.id),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: task.id == widget.selectedTaskId ? tt.selected : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TaskCheckbox(
                        status: task.status,
                        priority: task.priority,
                        kind: task.kind,
                        onTap: () => unawaited(toggleComplete(context, ref, task)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Highlighted(
                              text: task.title.isEmpty ? t.untitled : task.title,
                              hit: hit.field == SearchField.title ? hit : null,
                              style: TextStyle(color: task.status == TaskStatus.open ? tt.text : tt.textTertiary, fontSize: TtText.body),
                            ),
                            if (hit.snippet.isNotEmpty && (hit.field != SearchField.title || _query.text.trim().isEmpty))
                              _Highlighted(
                                text: hit.snippet,
                                hit: hit.field == SearchField.title ? null : hit,
                                style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
                                maxLines: 2,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (list != null)
                        Text(
                          labels.listName(list),
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                      if (due != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          dates.rowDate(due, isAllDay: task.isAllDay, today: today),
                          style: TextStyle(fontSize: TtText.small, color: tt.primary),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Menu value that clears a filter ("Todas").
class _All {
  const _All();
}

class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.hit, required this.style, this.maxLines = 1});

  final String text;
  final SearchHit? hit;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final h = hit;
    if (h == null || h.matchLength == 0 || h.matchStart + h.matchLength > text.length) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final end = h.matchStart + h.matchLength;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, h.matchStart)),
          TextSpan(
            text: text.substring(h.matchStart, end),
            style: TextStyle(color: context.tt.primary, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
