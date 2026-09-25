import 'dart:async';

import '../common/emoji_picker.dart';
import '../filters/filter_dialog.dart' show filterDateLabel;
import '../../domain/filters.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/matrix.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';
import '../detail/task_detail_pane.dart';
import '../shell/app_shell.dart';
import '../tasks/quick_add_modal.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_row.dart';

/// Eisenhower Matrix (`#m/all/matrix`): four quadrants with their rules; a task dragged
/// to another quadrant takes its priority (with its subtasks).
class MatrixPage extends ConsumerWidget {
  const MatrixPage({super.key});

  static List<String> defaultNames(AppLocalizations t) => [t.matrixQ1, t.matrixQ2, t.matrixQ3, t.matrixQ4];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final colors = [tt.palette.priorityHigh, tt.palette.priorityMedium, tt.palette.priorityLow, tt.textTertiary];
    Widget quadrant(int i) => _Quadrant(index: i, rule: prefs.matrixRules[i], color: colors[i], hideCompleted: prefs.matrixHideCompleted);

    final page = Container(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
            child: Row(
              children: [
                const DrawerMenuButton(),
                Expanded(
                  child: Text(
                    t.navMatrix,
                    style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '',
                  icon: Icon(Icons.more_horiz, color: tt.textSecondary),
                  onSelected: (_) => unawaited(ref.read(preferencesRepositoryProvider).setMatrixHideCompleted(hide: !prefs.matrixHideCompleted)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'completed',
                      height: 36,
                      child: Text(prefs.matrixHideCompleted ? t.matrixShowCompleted : t.matrixHideCompleted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: narrow
                // Phones: the grid scrolls sideways.
                ? ListView(
                    scrollDirection: Axis.horizontal,
                    children: [for (var i = 0; i < 4; i++) SizedBox(width: MediaQuery.sizeOf(context).width * 0.85, child: quadrant(i))],
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: quadrant(0)),
                              Expanded(child: quadrant(1)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: quadrant(2)),
                              Expanded(child: quadrant(3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
    return ModuleScaffold(module: AppModule.matrix, child: page);
  }
}

class _Quadrant extends ConsumerWidget {
  const _Quadrant({required this.index, required this.rule, required this.color, required this.hideCompleted});

  final int index;
  final QuadrantRule rule;
  final Color color;
  final bool hideCompleted;

  static const _roman = ['I', 'II', 'III', 'IV'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final tasks = quadrantTasks(s, rule, hideCompleted: hideCompleted, now: now);
    final name = rule.name ?? MatrixPage.defaultNames(t)[index];
    // A quadrant with a single priority is where the "+" creates with that priority.
    final dropPriority = rule.priorities.length == 1 ? rule.priorities.first : null;

    // A dragged task takes the priority and, with a "Data" rule, the date of the quadrant.
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => rule.priorities.isNotEmpty || rule.dates.isNotEmpty,
      onAcceptWithDetails: (d) => unawaited(_drop(ref, d.data, rule, startOfDay(now))),
      builder: (context, candidates, _) => Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? color.withValues(alpha: 0.08) : tt.fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: candidates.isNotEmpty ? color : tt.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      rule.icon ?? _roman[index],
                      style: TextStyle(color: Colors.white, fontSize: rule.icon == null ? 11 : 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                  Text(
                    '${tasks.length}',
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: t.addTask,
                    icon: Icon(Icons.add, size: 18, color: tt.textTertiary),
                    onPressed: () => unawaited(
                      showQuickAddModal(
                        context,
                        target: const AddTarget(listId: inboxListId, hint: AddPlainHint()),
                        priority: dropPriority ?? Priority.none,
                      ),
                    ),
                  ),
                  PopupMenuButton<Object>(
                    tooltip: '',
                    icon: Icon(Icons.more_horiz, size: 18, color: tt.textTertiary),
                    onSelected: (v) async {
                      final repo = ref.read(preferencesRepositoryProvider);
                      final rules = [...(ref.read(preferencesProvider).value ?? Preferences.defaults).matrixRules];
                      if (v == 'restore') {
                        rules[index] = QuadrantRule.defaults[index];
                        await repo.setMatrixRules(rules);
                      } else if (v is int) {
                        // "Reordenar": the two quadrants trade places (name and rules).
                        final other = rules[v];
                        rules[v] = rules[index];
                        rules[index] = other;
                        await repo.setMatrixRules(rules);
                      } else if (v is QuadrantGrouping) {
                        rules[index] = rule.withView(grouping: v);
                        await repo.setMatrixRules(rules);
                      } else if (v is QuadrantSorting) {
                        rules[index] = rule.withView(sorting: v);
                        await repo.setMatrixRules(rules);
                      } else if (v is bool) {
                        rules[index] = rule.withView(ascending: v);
                        await repo.setMatrixRules(rules);
                      } else {
                        final edited = await _editRule(context, ref, rule, MatrixPage.defaultNames(t)[index]);
                        if (edited is List<QuadrantRule>) {
                          await repo.setMatrixRules(edited);
                        } else if (edited is QuadrantRule) {
                          rules[index] = edited;
                          await repo.setMatrixRules(rules);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', height: 36, child: Text(t.countdownEdit)),
                      const PopupMenuDivider(),
                      _MenuTitle(t.matrixGroupBy),
                      for (final (g, label) in [
                        (QuadrantGrouping.time, t.matrixByTime),
                        (QuadrantGrouping.list, t.matrixByList),
                        (QuadrantGrouping.priority, t.matrixByPriority),
                        (QuadrantGrouping.tag, t.matrixByTag),
                        (QuadrantGrouping.none, t.matrixByNone),
                      ])
                        _checkItem(g, checked: rule.grouping == g, label: label),
                      const PopupMenuDivider(),
                      _MenuTitle(t.matrixSortBy),
                      for (final (o, label) in [
                        (QuadrantSorting.time, t.matrixByTime),
                        (QuadrantSorting.title, t.matrixByTitle),
                        (QuadrantSorting.priority, t.matrixByPriority),
                        (QuadrantSorting.tag, t.matrixByTag),
                      ])
                        _checkItem(o, checked: rule.sorting == o, label: label),
                      const PopupMenuDivider(),
                      _MenuTitle(t.matrixOrder),
                      _checkItem(true, checked: rule.ascending, label: t.matrixAscending),
                      _checkItem(false, checked: !rule.ascending, label: t.matrixDescending),
                      const PopupMenuDivider(),
                      for (var other = 0; other < 4; other++)
                        if (other != index)
                          PopupMenuItem<Object>(
                            value: other,
                            height: 32,
                            child: Text(
                              t.matrixSwapWith(
                                (ref.read(preferencesProvider).value ?? Preferences.defaults).matrixRules[other].name ??
                                    MatrixPage.defaultNames(t)[other],
                              ),
                            ),
                          ),
                      const PopupMenuDivider(),
                      PopupMenuItem(value: 'restore', height: 36, child: Text(t.matrixRestore)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final (header, items) in groupQuadrant(s, tasks, now, grouping: rule.grouping)) ...[
                    if (header is! NoHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 12, 2),
                        child: Text(
                          '${labels.header(header, s, now)} ${items.length}',
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    for (final task in items) _MatrixRow(task: task, now: now),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drop(WidgetRef ref, String taskId, QuadrantRule rule, DateTime today) async {
    final repo = ref.read(repositoryProvider);
    final task = ref.read(snapshotProvider).value?.taskById[taskId];
    if (task == null) return;
    final change = quadrantDrop(task, rule, today);
    if (change.priority case final p?) await repo.setPriorityWithSubtasks(taskId, p);
    final day = change.day;
    if (day == null) return;
    // A timed task keeps its time (and length) on the new day.
    final start = task.startLocal, due = task.endLocal;
    if (task.isAllDay || start == null || due == null) {
      await repo.setDueDate(taskId, day, isAllDay: true);
    } else {
      final shift = Duration(days: daysBetween(startOfDay(start), day));
      await repo.setDueDate(taskId, due.add(shift), isAllDay: false, startDate: start.add(shift));
    }
  }

  /// "Editar Matriz": name, lists, tags, date, priorities and type of the quadrant.
  /// Returns the rule, or the four rules of an "Exemplos" preset.
  Future<Object?> _editRule(BuildContext context, WidgetRef ref, QuadrantRule rule, String defaultName) {
    final t = AppLocalizations.of(context);
    final labels = Labels(t);
    final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
    final name = TextEditingController(text: rule.name ?? defaultName);
    final priorities = {...rule.priorities};
    final lists = {...rule.listIds};
    final tags = {...rule.tagIds};
    final kinds = {...rule.kinds};
    final dates = {...rule.dates};
    var excludeDates = rule.excludeDates;
    String? icon = rule.icon;
    return showDialog<Object>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Widget chips<T>(String title, Map<T, String> options, Set<T> selected) => Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: context.tt.textSecondary, fontSize: TtText.small),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    FilterChip(
                      label: Text(t.matrixAll),
                      selected: selected.isEmpty,
                      showCheckmark: false,
                      onSelected: (_) => setState(selected.clear),
                    ),
                    for (final o in options.entries)
                      FilterChip(
                        label: Text(o.value),
                        selected: selected.contains(o.key),
                        showCheckmark: false,
                        onSelected: (on) => setState(() => on ? selected.add(o.key) : selected.remove(o.key)),
                      ),
                  ],
                ),
              ],
            ),
          );
          return AlertDialog(
            title: Text(t.matrixEditTitle, style: const TextStyle(fontSize: 15)),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        // Icon of the quadrant: an emoji, or the roman numeral.
                        IconButton(
                          tooltip: t.countdownIcon,
                          icon: icon == null ? const Icon(Icons.add_reaction_outlined, size: 20) : Text(icon!, style: const TextStyle(fontSize: 20)),
                          onPressed: () async {
                            final picked = await showEmojiPicker(context);
                            if (picked != null) setState(() => icon = picked.isEmpty ? null : picked);
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: name,
                            decoration: InputDecoration(labelText: t.matrixName),
                          ),
                        ),
                      ],
                    ),
                    chips(t.searchFilterLists, {for (final l in s.activeLists) l.id: labels.listName(l)}, lists),
                    chips(t.searchFilterTag, {for (final tag in s.activeTags) tag.id: tag.name}, tags),
                    chips(t.searchFilterDate, {for (final d in FilterDate.values) d: filterDateLabel(t, d)}, dates),
                    // "é" / "não é" for the dates, as in the advanced filters.
                    if (dates.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => setState(() => excludeDates = !excludeDates),
                          child: Text(excludeDates ? t.filterIsNot : t.filterIs),
                        ),
                      ),
                    chips(t.searchFilterPriority, {for (final p in Priority.values.reversed) p: labels.priority(p)}, priorities),
                    chips(t.searchFilterType, {TaskKind.text: t.searchTypeTask, TaskKind.note: t.searchTypeNote}, kinds),
                  ],
                ),
              ),
            ),
            actions: [
              // "Exemplos": the two ready-made rule sets, for the four quadrants.
              PopupMenuButton<List<QuadrantRule>>(
                tooltip: '',
                onSelected: (preset) => Navigator.pop(context, preset),
                itemBuilder: (_) => [
                  PopupMenuItem(value: QuadrantRule.defaults, height: 36, child: Text(t.matrixPresetPriority)),
                  PopupMenuItem(value: QuadrantRule.timeAndPriority, height: 36, child: Text(t.matrixPresetTime)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(t.matrixExamples, style: TextStyle(color: context.tt.primary)),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  QuadrantRule(
                    name: name.text.trim().isEmpty || name.text.trim() == defaultName ? null : name.text.trim(),
                    icon: icon,
                    priorities: priorities,
                    listIds: lists,
                    tagIds: tags,
                    kinds: kinds.contains(TaskKind.text) ? {...kinds, TaskKind.checklist} : kinds,
                    dates: dates,
                    excludeDates: dates.isNotEmpty && excludeDates,
                    grouping: rule.grouping,
                    sorting: rule.sorting,
                    ascending: rule.ascending,
                  ),
                ),
                child: Text(t.actionSave),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A compact menu row with a check mark when [checked].
PopupMenuItem<Object> _checkItem(Object value, {required bool checked, required String label}) => PopupMenuItem<Object>(
  value: value,
  height: 32,
  child: Row(
    children: [
      SizedBox(width: 26, child: checked ? const Icon(Icons.check, size: 16) : null),
      Text(label),
    ],
  ),
);

/// A section title inside a menu ("Agrupar por").
class _MenuTitle extends PopupMenuEntry<Object> {
  const _MenuTitle(this.text);

  final String text;

  @override
  double get height => 28;

  @override
  bool represents(Object? value) => false;

  @override
  State<_MenuTitle> createState() => _MenuTitleState();
}

class _MenuTitleState extends State<_MenuTitle> {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
    child: Text(
      widget.text,
      style: TextStyle(fontSize: TtText.small, color: context.tt.textTertiary),
    ),
  );
}

class _MatrixRow extends ConsumerWidget {
  const _MatrixRow({required this.task, required this.now});

  final Task task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final list = s.listById[task.listId];
    final due = task.dueDate?.toLocal();
    final today = startOfDay(now);
    final overdue = task.status == TaskStatus.open && (task.daysToEnd(today) ?? 0) < 0;
    final row = InkWell(
      // The detail opens over the Matrix.
      onTap: () => unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: SizedBox(
              width: 560,
              height: 680,
              child: TaskDetailPane(scope: ListScope(task.listId), taskId: task.id),
            ),
          ),
        ),
      ),
      onSecondaryTapUp: (d) => unawaited(showTaskMenu(context, ref, task, d.globalPosition)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            TaskCheckbox(status: task.status, priority: task.priority, kind: task.kind, onTap: () => unawaited(toggleComplete(context, ref, task))),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title.isEmpty ? t.untitled : task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: task.status == TaskStatus.open ? tt.text : tt.textTertiary, fontSize: TtText.body),
              ),
            ),
            if (list != null) Text('${list.emoji ?? ''} ${Labels(t).listName(list)}', style: TextStyle(fontSize: 11, color: tt.textTertiary)),
            if (due != null) ...[
              const SizedBox(width: 8),
              Text(
                DateLabels(t).rowDate(due, isAllDay: task.isAllDay, today: today),
                style: TextStyle(fontSize: 11, color: overdue ? tt.overdue : tt.primary),
              ),
            ],
          ],
        ),
      ),
    );
    return Draggable<String>(
      data: task.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(6)),
          child: Text(task.title, style: TextStyle(color: tt.text)),
        ),
      ),
      child: row,
    );
  }
}
