import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/sort_order.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';

/// Checklist-mode items: Enter adds the next item, Backspace on an empty item removes it,
/// checked items move to the end.
class ChecklistEditor extends ConsumerStatefulWidget {
  const ChecklistEditor({super.key, required this.taskId, required this.items});

  final String taskId;
  final List<ChecklistItem> items;

  @override
  ConsumerState<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends ConsumerState<ChecklistEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focus = {};
  String? _focusNext;

  /// Order shown right after a drag, until the database catches up.
  List<String>? _order;

  TextEditingController _controller(ChecklistItem i) => _controllers.putIfAbsent(i.id, () => TextEditingController(text: i.title));

  FocusNode _node(ChecklistItem i) => _focus.putIfAbsent(i.id, () {
    final node = FocusNode(onKeyEvent: (_, event) => _onKey(i, event));
    node.addListener(() {
      if (!node.hasFocus) _saveTitle(i);
    });
    return node;
  });

  KeyEventResult _onKey(ChecklistItem item, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _controller(item).text.isEmpty) {
      unawaited(ref.read(repositoryProvider).deleteChecklistItem(item.id));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _saveTitle(ChecklistItem i) {
    final text = _controllers[i.id]?.text;
    if (text != null && text != i.title) unawaited(ref.read(repositoryProvider).setChecklistItemTitle(i.id, text));
  }

  /// Dragging an open item by its handle; checked items stay at the end.
  Future<void> _reorder(List<ChecklistItem> open, int from, int to) async {
    // [to] already counts without the moved item (onReorderItem).
    if (from >= open.length) return;
    final target = to.clamp(0, open.length - 1);
    if (target == from) return;
    final orders = SortOrder.moved([for (final i in open) i.sortOrder], from, target);
    final ids = [for (final i in open) i.id];
    final moved = ids.removeAt(from);
    ids.insert(target, moved);
    final before = {for (final i in open) i.id: i.sortOrder};
    setState(() => _order = ids);
    final repo = ref.read(repositoryProvider);
    for (var k = 0; k < ids.length; k++) {
      if (before[ids[k]] != orders[k]) await repo.reorderChecklistItem(ids[k], orders[k]);
    }
  }

  Future<void> _addAfter(ChecklistItem? item) async {
    if (item != null) _saveTitle(item);
    final id = await ref.read(repositoryProvider).addChecklistItem(widget.taskId, afterItemId: item?.id);
    setState(() => _focusNext = id);
  }

  Future<void> _pickDate(ChecklistItem item) async {
    final picked = await showTtDatePicker(
      context,
      initial: DateSelection(dueDate: item.dueDate?.toLocal(), isAllDay: item.isAllDay),
      now: ref.read(clockProvider).now(),
      dateOnly: true,
    );
    if (picked != null) await ref.read(repositoryProvider).setChecklistItemDate(item.id, picked.dueDate, isAllDay: picked.isAllDay);
  }

  @override
  void didUpdateWidget(ChecklistEditor old) {
    super.didUpdateWidget(old);
    if (!identical(old.items, widget.items)) _order = null;
    for (final i in widget.items) {
      final c = _controllers[i.id];
      if (c != null && !(_focus[i.id]?.hasFocus ?? false) && c.text != i.title) c.text = i.title;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    var open = widget.items.where((i) => !i.isCompleted).toList();
    final pending = _order;
    if (pending != null && pending.length == open.length) {
      final byId = {for (final i in open) i.id: i};
      if (pending.every(byId.containsKey)) open = [for (final id in pending) byId[id]!];
    }
    final ordered = [...open, ...widget.items.where((i) => i.isCompleted)];
    final done = widget.items.length - open.length;
    if (_focusNext != null) {
      final target = _focusNext!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = _focus[target];
        if (node != null) {
          node.requestFocus();
          _focusNext = null;
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress of the checklist.
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: done / widget.items.length, minHeight: 3, color: tt.primary, backgroundColor: tt.divider),
            ),
          ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (from, to) => unawaited(_reorder(open, from, to)),
          children: [
            for (final (index, i) in ordered.indexed)
              SizedBox(
                key: ValueKey(i.id),
                height: 34,
                child: Row(
                  children: [
                    // The handle drags open items; checked ones stay at the end.
                    SizedBox(
                      width: 18,
                      child: i.isCompleted
                          ? null
                          : ReorderableDragStartListener(
                              index: index,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: Icon(Icons.drag_indicator, size: 14, color: tt.textFaint),
                              ),
                            ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Checkbox(
                        value: i.isCompleted,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: tt.textTertiary, width: 1.5),
                        onChanged: (v) => unawaited(ref.read(repositoryProvider).setChecklistItemCompleted(i.id, completed: v ?? false)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller(i),
                        focusNode: _node(i),
                        style: TextStyle(
                          fontSize: TtText.body,
                          color: i.isCompleted ? tt.textTertiary : tt.text,
                          decoration: i.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                        onSubmitted: (_) => unawaited(_addAfter(i)),
                      ),
                    ),
                    // Reminder of the item: its date, or the clock icon to set one.
                    if (i.dueDate case final DateTime date)
                      InkWell(
                        onTap: () => unawaited(_pickDate(i)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            DateLabels(t).rowDate(date.toLocal(), isAllDay: i.isAllDay, today: startOfDay(ref.watch(clockProvider).now())),
                            style: TextStyle(fontSize: TtText.small, color: i.isCompleted ? tt.textTertiary : tt.primary),
                          ),
                        ),
                      )
                    else
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: t.checklistItemReminder,
                        icon: Icon(Icons.alarm_add_outlined, size: 15, color: tt.textFaint),
                        onPressed: () => unawaited(_pickDate(i)),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 14, color: tt.textFaint),
                      onPressed: () => unawaited(ref.read(repositoryProvider).deleteChecklistItem(i.id)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        TextButton.icon(
          style: TextButton.styleFrom(alignment: Alignment.centerLeft, foregroundColor: tt.textTertiary),
          onPressed: () => unawaited(_addAfter(widget.items.isEmpty ? null : widget.items.last)),
          icon: const Icon(Icons.add, size: 16),
          label: Text(t.detailChecklistHint, style: const TextStyle(fontSize: TtText.small)),
        ),
      ],
    );
  }
}
