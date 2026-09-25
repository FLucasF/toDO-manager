import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../core/sort_order.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import 'quick_add_input.dart';
import 'section_menu.dart';
import 'task_actions.dart';
import 'task_row.dart';

/// One Kanban column: a section of the list, or a group of the view (a day, a priority…).
class _Column {
  const _Column({required this.key, required this.title, required this.rows, this.section, this.unsectioned = false, this.header});

  final String key;
  final String title;
  final List<TaskRow> rows;
  final Section? section;

  /// "Não Classificado" of a list.
  final bool unsectioned;
  final GroupHeader? header;

  bool get isSectionColumn => section != null || unsectioned;
}

/// Kanban view: a column per section plus "Não Classificado" (in lists) or per group (in
/// smart lists, tags and folders). Cards move between columns by dragging; section columns are
/// reordered by dragging their header; "+ Nova seção" closes the board.
class KanbanBoard extends ConsumerWidget {
  const KanbanBoard({super.key, required this.scope, required this.view, required this.selectedTaskId});

  final Scope scope;
  final ViewContent view;
  final String? selectedTaskId;

  static const columnWidth = 280.0;

  List<_Column> _columns(Snapshot s, Labels labels, DateTime today) {
    final scope = this.scope;
    final isSectioned = view.groups.any((g) => g.header is UnsectionedHeader || g.header is SectionHeader);
    if (scope is ListScope && (isSectioned || view.groups.every((g) => g.header is NoHeader || g.header is PinnedHeader || g.isClosed))) {
      // Pinned tasks go to their own section's column.
      final pinned = [for (final g in view.groups.where((g) => g.header is PinnedHeader)) ...g.rows.where((r) => r.depth == 0)];
      List<TaskRow> rowsOf(String? sectionId, List<TaskRow> own) => [
        ...pinned.where(
          (r) => r.task.sectionId == sectionId || (sectionId == null && !s.sectionsOf(scope.listId).any((x) => x.id == r.task.sectionId)),
        ),
        ...own.where((r) => r.depth == 0),
      ];
      final unsectioned = view.groups.where((g) => g.header is UnsectionedHeader || g.header is NoHeader).expand((g) => g.rows).toList();
      return [
        _Column(key: 'section:', title: labels.t.groupUnsectioned, rows: rowsOf(null, unsectioned), unsectioned: true),
        for (final sec in s.sectionsOf(scope.listId))
          _Column(
            key: 'section:${sec.id}',
            title: sec.name,
            section: sec,
            rows: rowsOf(sec.id, view.groups.where((g) => g.sectionId == sec.id).expand((g) => g.rows).toList()),
          ),
      ];
    }
    return [
      for (final g in view.groups)
        _Column(
          key: g.key,
          // The overdue column is "Em atraso" in the Kanban.
          title: switch (g.header) {
            NoHeader() => labels.t.groupUnsectioned,
            OverdueHeader() => labels.t.kanbanOverdue,
            final header => labels.header(header, s, today),
          },
          rows: g.rows.where((r) => r.depth == 0).toList(),
          header: g.header,
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final columns = _columns(s, Labels(t), startOfDay(now));
    final scope = this.scope;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        for (final c in columns) _KanbanColumn(scope: scope, column: c, columns: columns, view: view, selectedTaskId: selectedTaskId, now: now),
        if (scope is ListScope) _NewSectionColumn(listId: scope.listId),
      ],
    );
  }
}

class _KanbanColumn extends ConsumerStatefulWidget {
  const _KanbanColumn({
    required this.scope,
    required this.column,
    required this.columns,
    required this.view,
    required this.selectedTaskId,
    required this.now,
  });

  final Scope scope;
  final _Column column;
  final List<_Column> columns;
  final ViewContent view;
  final String? selectedTaskId;
  final DateTime now;

  @override
  ConsumerState<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<_KanbanColumn> {
  bool _adding = false;
  bool _hovering = false;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  _Column get _c => widget.column;

  String? get _listId => switch (widget.scope) {
    ListScope(:final listId) => listId,
    _ => null,
  };

  /// Whether a card dropped here can take this column's value.
  bool get _acceptsCards => _c.isSectionColumn || _c.header is DayHeader || _c.header is NoDateHeader;

  Future<void> _dropCard(String taskId, {String? beforeId}) async {
    final repo = ref.read(repositoryProvider);
    if (_c.isSectionColumn) {
      final sectionId = _c.section?.id;
      if (beforeId != null && beforeId != taskId) {
        await repo.moveBefore(taskId, beforeId, sectionId: Value(sectionId));
      } else {
        await repo.moveToSectionTop(taskId, _listId!, sectionId);
      }
      return;
    }
    final header = _c.header;
    if (header is DayHeader) {
      // Keeps the time of day of a timed task.
      final task = ref.read(snapshotProvider).value?.taskById[taskId];
      final due = task?.dueDate?.toLocal();
      final day = header.day;
      final timed = task != null && !task.isAllDay && due != null;
      await repo.setDueDate(taskId, timed ? DateTime(day.year, day.month, day.day, due.hour, due.minute) : day, isAllDay: !timed);
    } else if (header is NoDateHeader) {
      await repo.setSchedule(taskId, dueDate: null);
    }
  }

  /// Dropping a section column before this one reorders the sections.
  Future<void> _dropColumn(Section moved) async {
    final target = _c.section;
    if (target == null || target.id == moved.id) return;
    final sections = ref.read(snapshotProvider).value?.sectionsOf(target.listId) ?? const <Section>[];
    final i = sections.indexWhere((x) => x.id == target.id);
    final previous = i > 0 ? sections[i - 1] : null;
    final order = previous == null || previous.id == moved.id
        ? SortOrder.before(target.sortOrder)
        : SortOrder.between(previous.sortOrder, target.sortOrder);
    if (order != null) await ref.read(repositoryProvider).reorderSection(moved.id, order);
  }

  Future<void> _add(String text) async {
    final t = AppLocalizations.of(context);
    final base = widget.view.addTarget;
    final header = _c.header;
    final target = AddTarget(
      listId: _listId ?? base?.listId ?? inboxListId,
      hint: base?.hint ?? const AddPlainHint(),
      dueDate: header is DayHeader ? header.day : base?.dueDate,
      tagId: base?.tagId,
    );
    final id = await createFromQuickAdd(ref, t, text: text, target: target, sectionId: _c.section?.id);
    if (id == null) return;
    _controller.clear();
    _focus.requestFocus();
  }

  Future<void> _sectionMenu(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width, box.size.height));
    await showSectionMenu(
      context,
      ref,
      _c.section!,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      columns: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final section = _c.section;

    final header = SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, color: tt.text, fontSize: TtText.body),
            ),
          ),
          Text(
            '${_c.rows.length}',
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: t.addTask,
            icon: Icon(Icons.add, size: 18, color: tt.textTertiary),
            onPressed: () => setState(() {
              _adding = true;
              _focus.requestFocus();
            }),
          ),
          if (section != null)
            Builder(
              builder: (context) => IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.more_horiz, size: 18, color: tt.textTertiary),
                onPressed: () => unawaited(_sectionMenu(context)),
              ),
            ),
        ],
      ),
    );

    final body = DragTarget<String>(
      onWillAcceptWithDetails: (_) => _acceptsCards,
      onAcceptWithDetails: (d) => unawaited(_dropCard(d.data)),
      builder: (context, candidates, _) => Container(
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? tt.primary.withValues(alpha: 0.06) : tt.fieldFill,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(6),
        // Built lazily, so a column with hundreds of cards stays smooth.
        child: ListView.builder(
          itemCount: _c.rows.length + (_adding ? 1 : 0),
          itemBuilder: (context, index) {
            if (_adding && index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: tt.screen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tt.primary),
                ),
                child: Focus(
                  onFocusChange: (focused) {
                    if (!focused && _controller.text.trim().isEmpty) setState(() => _adding = false);
                  },
                  child: QuickAddTextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    hint: t.addTask,
                    onSubmitted: (text) => unawaited(_add(text)),
                  ),
                ),
              );
            }
            final row = _c.rows[index - (_adding ? 1 : 0)];
            return _KanbanCard(
              key: ValueKey(row.task.id),
              scope: widget.scope,
              row: row,
              selected: row.task.id == widget.selectedTaskId,
              now: widget.now,
              onDropBefore: _c.isSectionColumn ? (taskId) => unawaited(_dropCard(taskId, beforeId: row.task.id)) : null,
            );
          },
        ),
      ),
    );

    final column = Container(
      width: KanbanBoard.columnWidth,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section headers drag to reorder the sections.
          if (section != null)
            Draggable<Section>(
              data: section,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: KanbanBoard.columnWidth,
                  child: Opacity(opacity: 0.8, child: header),
                ),
              ),
              child: DragTarget<Section>(
                onWillAcceptWithDetails: (d) => d.data.id != section.id,
                onAcceptWithDetails: (d) => unawaited(_dropColumn(d.data)),
                onMove: (_) => setState(() => _hovering = true),
                onLeave: (_) => setState(() => _hovering = false),
                builder: (context, _, _) => Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: _hovering ? tt.primary : Colors.transparent, width: 2)),
                  ),
                  child: header,
                ),
              ),
            )
          else
            header,
          Expanded(child: body),
        ],
      ),
    );
    return column;
  }
}

class _KanbanCard extends ConsumerWidget {
  const _KanbanCard({super.key, required this.scope, required this.row, required this.selected, required this.now, this.onDropBefore});

  final Scope scope;
  final TaskRow row;
  final bool selected;
  final DateTime now;

  /// Dropping a card on this one puts it just before (section columns).
  final void Function(String taskId)? onDropBefore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final task = row.task;
    final today = startOfDay(now);
    final due = task.dueDate?.toLocal();
    final overdue = task.status == TaskStatus.open && (task.daysToEnd(today) ?? 0) < 0;
    final dates = DateLabels(t);
    final children = ref.watch(snapshotProvider).value?.childrenOf(task.id) ?? const <Task>[];

    final card = GestureDetector(
      onSecondaryTapUp: (d) => unawaited(showTaskMenu(context, ref, task, d.globalPosition)),
      onLongPressStart: (d) => unawaited(showTaskMenu(context, ref, task, d.globalPosition)),
      child: InkWell(
        onTap: () => context.go(Routes.of(scope, taskId: task.id)),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
          decoration: BoxDecoration(
            color: selected ? tt.selected : tt.screen,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tt.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskCheckbox(status: task.status, priority: task.priority, kind: task.kind, onTap: () => unawaited(toggleComplete(context, ref, task))),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title.isEmpty ? t.untitled : task.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.status == TaskStatus.open ? tt.text : tt.textTertiary,
                        fontSize: TtText.body,
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (due != null || row.tags.isNotEmpty || row.checklistProgress != null || children.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (due != null)
                              Text(
                                task.hasDuration
                                    ? dates.rowRange(task.startLocal!, due, isAllDay: task.isAllDay, today: today)
                                    : dates.rowDate(due, isAllDay: task.isAllDay, today: today),
                                style: TextStyle(fontSize: TtText.small, color: overdue ? tt.overdue : tt.primary),
                              ),
                            for (final tag in row.tags.take(2))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: (parseHexColor(tag.color) ?? tt.textTertiary).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(tag.name, style: TextStyle(fontSize: 11, color: tt.textSecondary)),
                              ),
                            if (row.checklistProgress != null) Icon(Icons.checklist, size: 14, color: tt.textTertiary),
                            if (children.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_tree_outlined, size: 13, color: tt.textTertiary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${children.where((c) => c.status != TaskStatus.open).length}/${children.length}',
                                    style: TextStyle(fontSize: 11, color: tt.textTertiary),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dropTarget = onDropBefore == null
        ? card
        : DragTarget<String>(
            onWillAcceptWithDetails: (d) => d.data != task.id,
            onAcceptWithDetails: (d) => onDropBefore!(d.data),
            builder: (context, candidates, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (candidates.isNotEmpty) Container(height: 2, margin: const EdgeInsets.only(bottom: 4), color: tt.primary),
                card,
              ],
            ),
          );

    return LongPressDraggable<String>(
      data: task.id,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: KanbanBoard.columnWidth - 12,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: dropTarget,
    );
  }
}

/// "+ Nova seção" after the last column: an inline field, Enter creates the section at the end.
class _NewSectionColumn extends ConsumerStatefulWidget {
  const _NewSectionColumn({required this.listId});

  final String listId;

  @override
  ConsumerState<_NewSectionColumn> createState() => _NewSectionColumnState();
}

class _NewSectionColumnState extends ConsumerState<_NewSectionColumn> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create(String name) async {
    if (name.trim().isEmpty) return;
    final sections = ref.read(snapshotProvider).value?.sectionsOf(widget.listId) ?? const <Section>[];
    await ref.read(repositoryProvider).createSection(widget.listId, name, sortOrder: SortOrder.after(sections.lastOrNull?.sortOrder));
    _controller.clear();
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return SizedBox(
      width: KanbanBoard.columnWidth,
      child: Align(
        alignment: Alignment.topLeft,
        child: _editing
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: t.sectionNew,
                    filled: true,
                    fillColor: tt.fieldFill,
                    contentPadding: const EdgeInsets.all(10),
                  ),
                  onSubmitted: (name) => unawaited(_create(name)),
                  onTapOutside: (_) => setState(() => _editing = false),
                ),
              )
            : TextButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.add, size: 16),
                label: Text(t.sectionNew),
                style: TextButton.styleFrom(foregroundColor: tt.textTertiary),
              ),
      ),
    );
  }
}
