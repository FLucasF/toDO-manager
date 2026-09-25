import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/calendar.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import '../tasks/export_print.dart';
import '../tasks/task_actions.dart';
import 'calendar_edit_page.dart';
import 'color_label_menu.dart';
import 'custom_recurrence_dialog.dart';
import 'recurring_scope.dart';

enum _Option { openDetail, duplicate, moveTo, print }

/// Places a popup beside [rect], as Google's beside the event: to its right, else to its left, level
/// with its top; by [near] (the click) when there is no room on either side, as for a wide block.
class BesideRect extends SingleChildLayoutDelegate {
  BesideRect(this.rect, {this.near});

  final Rect rect;
  final Offset? near;
  static const _gap = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.loose(constraints.biggest).deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double x;
    if (rect.right + _gap + childSize.width + 8 <= size.width) {
      x = rect.right + _gap;
    } else if (rect.left - _gap - childSize.width >= 8) {
      x = rect.left - _gap - childSize.width;
    } else {
      return NearPoint(near, gap: 12).getPositionForChild(size, childSize);
    }
    final y = rect.top.clamp(8.0, math.max(8.0, size.height - childSize.height - 8)).toDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(BesideRect old) => old.rect != rect || old.near != near;
}

/// "Sexta-feira, 25 de setembro · 08:00 – 12:00": when [e] happens, in words, as Google's popup.
String calendarWhen(DateLabels dates, CalendarEntry e, DateTime today) {
  String day(DateTime d, {bool weekday = false}) =>
      [if (weekday) '${dates.weekday(d)}, ', '${d.day} de ${dates.monthLong(d).toLowerCase()}', if (d.year != today.year) ' de ${d.year}'].join();
  final first = e.start, last = e.end;
  final oneDay = startOfDay(first) == startOfDay(last);
  if (e.isAllDay) return oneDay ? day(first, weekday: true) : '${day(first)} – ${day(last)}';
  final from = DateLabels.time(first);
  if (!last.isAfter(first) || e.task?.hasDuration == false) return '${day(first, weekday: true)} · $from';
  if (oneDay) return '${day(first, weekday: true)} · $from – ${DateLabels.time(last)}';
  return '${day(first)}, $from – ${day(last)}, ${DateLabels.time(last)}';
}

/// Google Calendar's details popup for a task clicked on the
/// calendar: Editar · Deletar · ⋮ · Fechar on top; its color and title, when, the repetition, the
/// reminders, the description and the list; "Marcar como concluída". It goes beside [anchor] (the
/// entry on the screen), else by [near], else centered. [onOpenDetail] opens TickTick's full detail
/// (⋮ → "Abrir detalhes da tarefa").
Future<void> showCalendarDetails(
  BuildContext context, {
  required CalendarEntry entry,
  required Color color,
  Rect? anchor,
  Offset? near,
  required VoidCallback onOpenDetail,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 100),
  pageBuilder: (context, _, _) => CustomSingleChildLayout(
    delegate: anchor != null ? BesideRect(anchor, near: near) : NearPoint(near, gap: 12),
    child: _DetailsPopup(entry: entry, color: color, onOpenDetail: onOpenDetail),
  ),
);

class _DetailsPopup extends ConsumerStatefulWidget {
  const _DetailsPopup({required this.entry, required this.color, required this.onOpenDetail});

  final CalendarEntry entry;
  final Color color;
  final VoidCallback onOpenDetail;

  @override
  ConsumerState<_DetailsPopup> createState() => _DetailsPopupState();
}

class _DetailsPopupState extends ConsumerState<_DetailsPopup> {
  // The popup's own context closes with it; toasts and the pages it opens use the calendar's.
  late final NavigatorState _navigator = Navigator.of(context);

  String get _id => widget.entry.task!.id;

  void _close() => _navigator.pop();

  Future<void> _edit() async {
    final task = ref.read(snapshotProvider).value?.taskById[_id];
    if (task == null) return;
    final reminders = ref.read(snapshotProvider).value?.remindersByTask[_id] ?? const <String>[];
    final outer = _navigator.context;
    _close();
    // An occurrence opens with its own dates; saving asks "Somente esta / … / Todas".
    await showTaskEditPage(outer, TaskDraft.of(task, reminders, occurrence: widget.entry.start));
  }

  Future<void> _delete() async {
    final task = ref.read(snapshotProvider).value?.taskById[_id] ?? widget.entry.task!;
    final repo = ref.read(repositoryProvider);
    final outer = _navigator.context;
    // A repeating task asks first: this occurrence, it and the following, or all.
    final scope = await scopeFor(context, task, widget.entry.start, delete: true);
    if (scope == null) return;
    _close();
    if (outer.mounted) await deleteOccurrence(outer, repo, task, widget.entry.start, scope);
  }

  Future<void> _toggleDone(bool done) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final outer = _navigator.context;
    _close();
    if (done) {
      await repo.reopen(_id);
    } else {
      await repo.complete(_id);
      if (outer.mounted) showToast(outer, t.toastTaskCompleted, undo: () => repo.reopen(_id), redo: () => repo.complete(_id));
    }
  }

  Future<void> _option(_Option o) async {
    final task = ref.read(snapshotProvider).value?.taskById[_id];
    if (task == null) return;
    final outer = _navigator.context;
    final t = AppLocalizations.of(context);
    _close();
    switch (o) {
      case _Option.openDetail:
        widget.onOpenDetail();
      case _Option.duplicate:
        await ref.read(repositoryProvider).duplicate(_id);
      case _Option.moveTo:
        if (outer.mounted) await moveTaskTo(outer, ref, task);
      case _Option.print:
        await printTask(ref, t, task);
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    // Google's keys in the popup: e edits, Delete / Backspace deletes.
    if (e.logicalKey == LogicalKeyboardKey.keyE) {
      unawaited(_edit());
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.delete || e.logicalKey == LogicalKeyboardKey.backspace) {
      unawaited(_delete());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final task = s.taskById[_id] ?? widget.entry.task!;
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final list = s.listById[task.listId];
    final reminders = s.remindersByTask[_id] ?? const <String>[];
    final tags = s.tagsOf(_id);
    final done = task.status != TaskStatus.open;
    final color = parseHexColor(task.color) ?? widget.color;
    final rule = task.repeatRule;
    final secondary = TextStyle(fontSize: TtText.body, color: tt.textSecondary);

    Widget action(IconData icon, String tooltip, VoidCallback onPressed) => IconButton(
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, color: tt.textSecondary),
      onPressed: onPressed,
    );

    Widget line(IconData icon, Widget child) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, child: Icon(icon, size: 20, color: tt.textSecondary)),
          Expanded(child: child),
        ],
      ),
    );

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tt.divider),
        ),
        child: SizedBox(
          width: 448,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    action(Icons.edit_outlined, t.calendarEditTask, () => unawaited(_edit())),
                    action(Icons.delete_outline, t.calendarDeleteTask, () => unawaited(_delete())),
                    PopupMenuButton<_Option>(
                      tooltip: t.calendarOptions,
                      icon: Icon(Icons.more_vert, size: 20, color: tt.textSecondary),
                      onSelected: (o) => unawaited(_option(o)),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: _Option.openDetail, height: 36, child: Text(t.calendarOpenDetail)),
                        PopupMenuItem(value: _Option.duplicate, height: 36, child: Text(t.menuDuplicate)),
                        PopupMenuItem(value: _Option.moveTo, height: 36, child: Text(t.menuMoveTo)),
                        PopupMenuItem(value: _Option.print, height: 36, child: Text(t.menuPrint)),
                      ],
                    ),
                    action(Icons.close, t.actionClose, _close),
                  ],
                ),
                // The color and the big title, then when.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 44,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 2),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title.isEmpty ? t.untitled : task.title,
                            style: TextStyle(
                              fontSize: 22,
                              color: done ? tt.textSecondary : tt.text,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(calendarWhen(dates, widget.entry, today), style: secondary),
                          if (rule != null) ...[
                            const SizedBox(height: 2),
                            Text(recurrenceSummary(t, dates, rule, task.startLocal ?? widget.entry.start), style: secondary),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (reminders.isNotEmpty)
                  line(
                    Icons.notifications_none,
                    Text(
                      [for (final r in reminders) reminderLabel(t, r)].join(', '),
                      style: TextStyle(fontSize: TtText.body, color: tt.text),
                    ),
                  ),
                if (task.content.trim().isNotEmpty)
                  line(
                    Icons.notes,
                    Text(
                      task.content.trim(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: TtText.body, color: tt.text),
                    ),
                  ),
                if (task.priority != Priority.none)
                  line(
                    Icons.flag,
                    Text(
                      '${t.menuPriority}: ${labels.priority(task.priority).toLowerCase()}',
                      style: TextStyle(fontSize: TtText.body, color: tt.priorityColor(task.priority)),
                    ),
                  ),
                if (tags.isNotEmpty)
                  line(
                    Icons.sell_outlined,
                    Text(
                      tags.map((tag) => tag.name).join(', '),
                      style: TextStyle(fontSize: TtText.body, color: tt.text),
                    ),
                  ),
                if (list != null)
                  line(
                    Icons.calendar_today_outlined,
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: parseHexColor(list.color) ?? tt.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            labels.listName(list),
                            style: TextStyle(fontSize: TtText.body, color: tt.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                // "Marcar como concluída", as Google's tasks; an occurrence of a repeating task is done from its date.
                if (!widget.entry.isOccurrence)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => unawaited(_toggleDone(done)), child: Text(done ? t.calendarMarkUndone : t.calendarMarkDone)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
