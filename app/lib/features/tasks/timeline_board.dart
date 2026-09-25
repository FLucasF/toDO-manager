import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/calendar.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/calendar_widgets.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import 'quick_add_modal.dart';
import 'task_actions.dart';
import 'task_row.dart';

const _namesWidth = 240.0;
const _rowHeight = 34.0;
const _groupHeight = 30.0;
const _rulerHeight = 44.0;

/// Whether a scope offers the timeline (lists, folders and filters, not the smart lists).
bool supportsTimeline(Scope scope) => scope is ListScope || scope is FolderScope || scope is FilterScope;

/// "Linha do tempo": the view's tasks as bars over a ruler of days, grouped like
/// the list; a bar is dragged to move the task and by its edges to change the start or the end. Tasks
/// without a date wait in "Organizar tarefas", to be dragged onto the ruler.
class TimelineBoard extends ConsumerStatefulWidget {
  const TimelineBoard({super.key, required this.scope, required this.view});

  final Scope scope;
  final ViewContent view;

  @override
  ConsumerState<TimelineBoard> createState() => _TimelineBoardState();
}

class _TimelineBoardState extends ConsumerState<TimelineBoard> {
  TimelineScale _scale = TimelineScale.day;
  DateTime? _start;
  bool _arrange = true;

  DateTime _today() => startOfDay(ref.read(clockProvider).now());

  /// A few days before today stay visible on the left.
  DateTime _startFor(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day -
        switch (_scale) {
          TimelineScale.day => 3,
          TimelineScale.week => 7,
          TimelineScale.month => 30,
        },
  );

  void _shift(int days) {
    final start = _start ?? _startFor(_today());
    setState(() => _start = DateTime(start.year, start.month, start.day + days));
  }

  int get _step => switch (_scale) {
    TimelineScale.day => 7,
    TimelineScale.week => 28,
    TimelineScale.month => 90,
  };

  Future<void> _setDates(Task t, ({DateTime start, DateTime due, bool isAllDay}) to) =>
      ref.read(repositoryProvider).setDueDate(t.id, to.due, isAllDay: to.isAllDay, startDate: to.start);

  Future<void> _drop(String taskId, DateTime day) async {
    final task = ref.read(snapshotProvider).value?.taskById[taskId];
    if (task == null) return;
    if (task.dueDate == null) {
      await ref.read(repositoryProvider).setDueDate(taskId, day);
    } else {
      await _setDates(task, movedDates(task, day));
    }
  }

  void _create(DateTime day, String? sectionId) {
    final target = widget.view.addTarget;
    if (target == null) return;
    unawaited(
      showQuickAddModal(
        context,
        target: target,
        schedule: DateSelection(dueDate: day),
        sectionId: sectionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final start = _start ?? _startFor(today);
    final colorBy = (ref.watch(preferencesProvider).value ?? Preferences.defaults).calendarOptions.colorBy;

    // The task's own color (Google's event color) over the list's.
    Color colorOf(Task task) =>
        parseHexColor(task.color) ??
        switch (colorBy) {
          CalendarColorBy.list => parseHexColor(s.listById[task.listId]?.color) ?? tt.primary,
          CalendarColorBy.tag => s.tagsOf(task.id).map((tag) => parseHexColor(tag.color)).nonNulls.firstOrNull ?? tt.primary,
          CalendarColorBy.priority => task.priority == Priority.none ? tt.primary : tt.priorityColor(task.priority),
        };

    // Dated tasks make the rows; the others wait in "Organizar tarefas".
    final groups = [
      for (final g in widget.view.groups)
        if (g.rows.where((r) => r.task.dueDate != null).toList() case final rows when rows.isNotEmpty) (g, rows),
    ];
    final undated = [
      for (final g in widget.view.groups)
        for (final r in g.rows)
          if (r.task.dueDate == null && r.task.status == TaskStatus.open) r.task,
    ];

    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
      child: Row(
        children: [
          SegmentedButton<TimelineScale>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: TimelineScale.day, label: Text(t.calendarModeDay)),
              ButtonSegment(value: TimelineScale.week, label: Text(t.calendarModeWeek)),
              ButtonSegment(value: TimelineScale.month, label: Text(t.calendarModeMonth)),
            ],
            selected: {_scale},
            onSelectionChanged: (v) => setState(() {
              _scale = v.first;
              _start = null;
            }),
          ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: tt.textSecondary,
              side: BorderSide(color: tt.divider),
            ),
            onPressed: () => setState(() => _start = null),
            child: Text(t.calendarToday),
          ),
          IconButton(
            icon: Icon(Icons.chevron_left, color: tt.textSecondary),
            onPressed: () => _shift(-_step),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: tt.textSecondary),
            onPressed: () => _shift(_step),
          ),
          IconButton(
            tooltip: t.calendarArrange,
            isSelected: _arrange,
            icon: Icon(Icons.view_sidebar_outlined, color: _arrange ? tt.primary : tt.textSecondary),
            onPressed: () => setState(() => _arrange = !_arrange),
          ),
        ],
      ),
    );

    final chart = LayoutBuilder(
      builder: (context, box) {
        final chartWidth = math.max(0.0, box.maxWidth - _namesWidth);
        final days = (chartWidth / _scale.dayWidth).ceil() + 1;
        final end = DateTime(start.year, start.month, start.day + days);
        double xOf(DateTime day) => daysBetween(start, day) * _scale.dayWidth;
        DateTime dayAt(double x) => DateTime(start.year, start.month, start.day + (x / _scale.dayWidth).floor());

        Widget chartCell({required Widget child, String? sectionId}) => SizedBox(
          width: chartWidth,
          child: CalendarDropArea(
            onDrop: (taskId, global) {
              final local = (context.findRenderObject()! as RenderBox).globalToLocal(global);
              unawaited(_drop(taskId, dayAt(local.dx - _namesWidth)));
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _create(dayAt(d.localPosition.dx), sectionId),
              child: ClipRect(
                child: CustomPaint(
                  painter: _DaysPainter(start: start, days: days, scale: _scale, today: today, line: tt.divider, todayColor: tt.primary),
                  child: child,
                ),
              ),
            ),
          ),
        );

        final rows = <Widget>[
          for (final (g, taskRows) in groups) ...[
            SizedBox(
              height: _groupHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: _namesWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: Text(
                        labels.header(g.header, s, now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w700, color: tt.textSecondary),
                      ),
                    ),
                  ),
                  chartCell(sectionId: g.sectionId, child: const SizedBox.expand()),
                ],
              ),
            ),
            for (final r in taskRows)
              SizedBox(
                height: _rowHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: _namesWidth,
                      child: InkWell(
                        onTap: () => context.go(Routes.of(widget.scope, taskId: r.task.id)),
                        child: Padding(
                          padding: EdgeInsets.only(left: 12 + 16.0 * r.depth, right: 8),
                          child: Row(
                            children: [
                              TaskCheckbox(
                                status: r.task.status,
                                priority: r.task.priority,
                                kind: r.task.kind,
                                onTap: () => unawaited(toggleComplete(context, ref, r.task)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r.task.title.isEmpty ? t.untitled : r.task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: TtText.body, color: r.task.status == TaskStatus.open ? tt.text : tt.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    chartCell(
                      sectionId: g.sectionId,
                      child: Stack(
                        children: [
                          if (!r.task.endLocal!.isBefore(start) && r.task.startLocal!.isBefore(end))
                            _Bar(
                              task: r.task,
                              left: xOf(startOfDay(r.task.startLocal!)),
                              width: (daysBetween(startOfDay(r.task.startLocal!), startOfDay(r.task.endLocal!)) + 1) * _scale.dayWidth,
                              dayWidth: _scale.dayWidth,
                              color: colorOf(r.task),
                              onOpen: () => context.go(Routes.of(widget.scope, taskId: r.task.id)),
                              onChange: (startDays, endDays) =>
                                  unawaited(_setDates(r.task, shiftedDates(r.task, startDays: startDays, endDays: endDays))),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ];

        return Listener(
          // Shift + wheel (or a sideways wheel) moves the days.
          onPointerSignal: (e) {
            if (e is! PointerScrollEvent) return;
            final dx = e.scrollDelta.dx != 0 ? e.scrollDelta.dx : (HardwareKeyboard.instance.isShiftPressed ? e.scrollDelta.dy : 0);
            if (dx != 0) _shift((dx / _scale.dayWidth).round().clamp(-_step, _step));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _rulerHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: _namesWidth),
                    SizedBox(
                      width: chartWidth,
                      child: ClipRect(
                        child: CustomPaint(
                          painter: _RulerPainter(
                            start: start,
                            days: days,
                            scale: _scale,
                            today: today,
                            labels: DateLabels(t),
                            text: tt.textSecondary,
                            faint: tt.textTertiary,
                            line: tt.divider,
                            todayColor: tt.primary,
                            base: DefaultTextStyle.of(context).style,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tt.divider),
              Expanded(
                child: groups.isEmpty
                    ? Stack(
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: _namesWidth),
                              Expanded(child: chartCell(child: const SizedBox.expand())),
                            ],
                          ),
                          Center(
                            child: IgnorePointer(
                              child: Text(
                                t.timelineEmpty,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: tt.textTertiary),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(padding: const EdgeInsets.only(bottom: 40), children: rows),
              ),
            ],
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toolbar,
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chart),
              if (_arrange) _Undated(tasks: undated, s: s),
            ],
          ),
        ),
      ],
    );
  }
}

/// A task's bar: dragged to move, by its edges to change the start or the end.
class _Bar extends StatefulWidget {
  const _Bar({
    required this.task,
    required this.left,
    required this.width,
    required this.dayWidth,
    required this.color,
    required this.onOpen,
    required this.onChange,
  });

  final Task task;
  final double left;
  final double width;
  final double dayWidth;
  final Color color;
  final VoidCallback onOpen;
  final void Function(int startDays, int endDays) onChange;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  double _dStart = 0;
  double _dEnd = 0;

  void _end() {
    final startDays = (_dStart / widget.dayWidth).round(), endDays = (_dEnd / widget.dayWidth).round();
    setState(() => _dStart = _dEnd = 0);
    if (startDays != 0 || endDays != 0) widget.onChange(startDays, endDays);
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final done = widget.task.status != TaskStatus.open;
    final left = widget.left + _dStart;
    final width = math.max(widget.dayWidth, widget.width - _dStart + _dEnd) - 2;
    Widget edge({required bool start}) => MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragUpdate: (d) => setState(() => start ? _dStart += d.delta.dx : _dEnd += d.delta.dx),
        onHorizontalDragEnd: (_) => _end(),
        child: const SizedBox(width: 6),
      ),
    );
    return Positioned(
      left: left + 1,
      width: width,
      top: 6,
      bottom: 6,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: done ? 0.12 : 0.35),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          // Stretched, so the 6 px edges take the bar's whole height.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            edge(start: true),
            Expanded(
              child: GestureDetector(
                onTap: widget.onOpen,
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragUpdate: (d) => setState(() {
                  _dStart += d.delta.dx;
                  _dEnd += d.delta.dx;
                }),
                onHorizontalDragEnd: (_) => _end(),
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.task.title,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(fontSize: 11, color: done ? tt.textTertiary : tt.text),
                  ),
                ),
              ),
            ),
            edge(start: false),
          ],
        ),
      ),
    );
  }
}

/// Day columns, weekends shaded, and today's line.
class _DaysPainter extends CustomPainter {
  const _DaysPainter({
    required this.start,
    required this.days,
    required this.scale,
    required this.today,
    required this.line,
    required this.todayColor,
  });

  final DateTime start;
  final int days;
  final TimelineScale scale;
  final DateTime today;
  final Color line;
  final Color todayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = line;
    for (var i = 0; i < days; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final x = i * scale.dayWidth;
      if (day.weekday >= DateTime.saturday) {
        canvas.drawRect(Rect.fromLTWH(x, 0, scale.dayWidth, size.height), Paint()..color = line.withValues(alpha: line.a * 0.6));
      }
      final boundary = switch (scale) {
        TimelineScale.day => true,
        TimelineScale.week => day.weekday == DateConventions.firstWeekday,
        TimelineScale.month => day.day == 1,
      };
      if (boundary) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final t = daysBetween(start, today);
    if (t >= 0 && t < days) {
      final x = t * scale.dayWidth + scale.dayWidth / 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = todayColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DaysPainter old) => old.start != start || old.days != days || old.scale != scale || old.today != today || old.line != line;
}

/// The ruler: months (years on the month scale) on top, days (months) below.
class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.start,
    required this.days,
    required this.scale,
    required this.today,
    required this.labels,
    required this.text,
    required this.faint,
    required this.line,
    required this.todayColor,
    required this.base,
  });

  final DateTime start;
  final int days;
  final TimelineScale scale;
  final DateTime today;
  final DateLabels labels;

  /// The app's text style (its font), which a TextPainter does not inherit.
  final TextStyle base;
  final Color text;
  final Color faint;
  final Color line;
  final Color todayColor;

  void _label(Canvas canvas, String s, double x, double y, {required Color color, FontWeight? weight, double maxWidth = 400}) {
    final painter = TextPainter(
      text: TextSpan(
        text: s,
        style: base.copyWith(fontSize: 11, color: color, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, maxWidth));
    painter.paint(canvas, Offset(x, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = line;
    String capital(String s) => '${s[0].toUpperCase()}${s.substring(1)}';
    for (var i = 0; i < days; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final x = i * scale.dayWidth;
      final isToday = day == today;
      switch (scale) {
        case TimelineScale.day:
          if (i == 0 || day.day == 1) _label(canvas, '${capital(labels.monthLong(day))} ${day.year}', x + 4, 4, color: text, weight: FontWeight.w600);
          _label(
            canvas,
            '${labels.weekdayShort(day)} ${day.day}',
            x + 4,
            24,
            color: isToday ? todayColor : faint,
            weight: isToday ? FontWeight.w700 : null,
            maxWidth: scale.dayWidth - 6,
          );
          canvas.drawLine(Offset(x, 22), Offset(x, size.height), paint);
        case TimelineScale.week:
          if (i == 0 || day.day == 1) _label(canvas, '${capital(labels.monthLong(day))} ${day.year}', x + 4, 4, color: text, weight: FontWeight.w600);
          _label(canvas, '${day.day}', x + 4, 24, color: isToday ? todayColor : faint, weight: isToday ? FontWeight.w700 : null);
          if (day.weekday == DateConventions.firstWeekday) canvas.drawLine(Offset(x, 22), Offset(x, size.height), paint);
        case TimelineScale.month:
          if (i == 0 || (day.month == 1 && day.day == 1)) _label(canvas, '${day.year}', x + 4, 4, color: text, weight: FontWeight.w600);
          if (i == 0 || day.day == 1) {
            _label(canvas, capital(labels.monthShort(day)), x + 4, 24, color: faint);
            canvas.drawLine(Offset(x, 22), Offset(x, size.height), paint);
          }
      }
    }
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.start != start || old.days != days || old.scale != scale || old.today != today || old.text != text;
}

/// "Organizar tarefas": open tasks of the view without a date, to drag onto the ruler.
class _Undated extends StatelessWidget {
  const _Undated({required this.tasks, required this.s});

  final List<Task> tasks;
  final Snapshot s;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: tt.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: Text(
              t.calendarArrange,
              style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(
              t.timelineArrangeHint,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(t.calendarArrangeEmpty, style: TextStyle(color: tt.textTertiary)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    children: [
                      for (final task in tasks)
                        calendarDraggable(
                          context,
                          taskId: task.id,
                          feedback: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tt.text, fontSize: TtText.small),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: tt.hover, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              task.title.isEmpty ? t.untitled : task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: TtText.body, color: tt.text),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
