import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/calendar.dart';
import '../../domain/enums.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_row.dart';
import 'calendar_widgets.dart';

const _laneHeight = 20.0;
const _dayNumberHeight = 26.0;

/// Weekday initials row (Sunday first).
class CalendarWeekdayHeader extends StatelessWidget {
  const CalendarWeekdayHeader({super.key, required this.from, this.leading = 0, this.days = _all});

  static const _all = [0, 1, 2, 3, 4, 5, 6];

  final DateTime from;
  final double leading;

  /// The days of the week shown, as offsets from [from] (without Saturday and Sunday when hidden).
  final List<int> days;

  @override
  Widget build(BuildContext context) {
    final labels = DateLabels(AppLocalizations.of(context));
    final tt = context.tt;
    return Padding(
      padding: EdgeInsets.only(left: leading, bottom: 4),
      child: Row(
        children: [
          for (final i in days)
            Expanded(
              child: Text(
                labels.weekdayShort(DateTime(from.year, from.month, from.day + i)).toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: tt.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Month and Multi-Semana: weeks of day cells with the entries as bars. Dragging over several days
/// creates a task that spans them ("arrastar sobre vários dias → tarefa multi-dia").
class CalendarMonthGrid extends StatefulWidget {
  const CalendarMonthGrid({
    super.key,
    required this.from,
    required this.weeks,
    required this.entries,
    required this.today,
    required this.actions,
    this.month,
    this.hideWeekends = false,
  });

  final DateTime from;
  final int weeks;
  final List<CalendarEntry> entries;
  final DateTime today;
  final CalendarActions actions;

  /// "Mostrar fins de semana" off: the weeks without Saturday and Sunday.
  final bool hideWeekends;

  /// The month shown (other days are dimmed); null in Multi-Semana.
  final int? month;

  @override
  State<CalendarMonthGrid> createState() => _CalendarMonthGridState();
}

class _CalendarMonthGridState extends State<CalendarMonthGrid> {
  /// Days under a drag that creates a task.
  DateTime? _dragFrom, _dragTo;

  /// The days of each week shown, as offsets from its first day.
  List<int> get _days => [
    for (var i = 0; i < 7; i++)
      if (!widget.hideWeekends || DateTime(widget.from.year, widget.from.month, widget.from.day + i).weekday < DateTime.saturday) i,
  ];

  DateTime _dayAt(Offset local, Size size) {
    final days = _days;
    final column = (local.dx / (size.width / days.length)).floor().clamp(0, days.length - 1);
    final row = (local.dy / (size.height / widget.weeks)).floor().clamp(0, widget.weeks - 1);
    return DateTime(widget.from.year, widget.from.month, widget.from.day + row * 7 + days[column]);
  }

  void _endDrag() {
    final from = _dragFrom, to = _dragTo;
    setState(() => _dragFrom = _dragTo = null);
    if (from == null || to == null || from == to) return;
    final (start, end) = from.isBefore(to) ? (from, to) : (to, from);
    widget.actions.create(DateSelection(startDate: start, dueDate: end));
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final days = _days;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          CalendarWeekdayHeader(from: widget.from, days: days),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                final from = _dragFrom, to = _dragTo;
                final (first, last) = from == null || to == null ? (null, null) : (from.isBefore(to) ? (from, to) : (to, from));
                return GestureDetector(
                  onPanStart: (d) => setState(() => _dragFrom = _dragTo = _dayAt(d.localPosition, size)),
                  onPanUpdate: (d) {
                    final day = _dayAt(d.localPosition, size);
                    if (day != _dragTo) setState(() => _dragTo = day);
                  },
                  onPanEnd: (_) => _endDrag(),
                  onPanCancel: () => setState(() => _dragFrom = _dragTo = null),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: tt.divider),
                        left: BorderSide(color: tt.divider),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            for (var w = 0; w < widget.weeks; w++)
                              Expanded(
                                child: _WeekRow(
                                  start: DateTime(widget.from.year, widget.from.month, widget.from.day + 7 * w),
                                  days: days,
                                  entries: widget.entries,
                                  today: widget.today,
                                  month: widget.month,
                                  actions: widget.actions,
                                ),
                              ),
                          ],
                        ),
                        // The days being dragged over.
                        if (first != null && last != null)
                          for (var i = 0; i <= daysBetween(first, last); i++)
                            if (daysBetween(widget.from, first) + i case final index when days.contains(index % 7))
                              Positioned(
                                left: days.indexOf(index % 7) * size.width / days.length,
                                top: index ~/ 7 * size.height / widget.weeks,
                                width: size.width / days.length,
                                height: size.height / widget.weeks,
                                child: IgnorePointer(child: ColoredBox(color: tt.primary.withValues(alpha: 0.15))),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.start, required this.days, required this.entries, required this.today, required this.month, required this.actions});

  final DateTime start;

  /// The days shown, as offsets from [start].
  final List<int> days;
  final List<CalendarEntry> entries;
  final DateTime today;
  final int? month;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / days.length;
        // Bars in the shown columns; an entry only on hidden days is left out.
        int? firstColumn(int from, int to) => [
          for (final (c, d) in days.indexed)
            if (d >= from && d <= to) c,
        ].firstOrNull;
        int? lastColumn(int from, int to) => [
          for (final (c, d) in days.indexed)
            if (d >= from && d <= to) c,
        ].lastOrNull;
        // Lanes are laid out for the entries that show, so a hidden weekend leaves no gap.
        final shown = days.length == 7
            ? entries
            : [
                for (final s in layoutSpans(entries, start, 7))
                  if (firstColumn(s.first, s.last) != null) s.entry,
              ];
        final slots = [
          for (final s in layoutSpans(shown, start, 7))
            if ((firstColumn(s.first, s.last), lastColumn(s.first, s.last)) case (final int first, final int last))
              (entry: s.entry, lane: s.lane, first: first, last: last),
        ];
        final fits = math.max(0, ((box.maxHeight - _dayNumberHeight - 2) / _laneHeight).floor());
        final overflow = slots.any((s) => s.lane >= fits);
        // With too many bars, the last lane shows "+N" for the days that hide some.
        final lanes = overflow ? math.max(0, fits - 1) : fits;
        List<CalendarEntry> ofDay(int i) => [
          for (final s in slots)
            if (s.first <= i && s.last >= i) s.entry,
        ];

        return Stack(
          children: [
            Row(
              children: [
                for (final i in days)
                  SizedBox(
                    width: cell,
                    height: box.maxHeight,
                    child: _DayCell(day: DateTime(start.year, start.month, start.day + i), today: today, month: month, actions: actions),
                  ),
              ],
            ),
            for (final s in slots)
              if (s.lane < lanes)
                Positioned(
                  left: s.first * cell + 2,
                  width: (s.last - s.first + 1) * cell - 4,
                  top: _dayNumberHeight + s.lane * _laneHeight,
                  height: _laneHeight - 2,
                  child: _Bar(entry: s.entry, actions: actions, width: cell - 4, days: s.last - s.first + 1),
                ),
            // "Mostrar números da semana" (Settings → Data e hora).
            if (DateConventions.weekNumbers)
              Positioned(
                right: cell * (days.length - 1) + 6,
                top: 6,
                child: IgnorePointer(
                  child: Text(t.weekNumber(isoWeekNumber(start)), style: TextStyle(fontSize: 10, color: tt.textFaint)),
                ),
              ),
            if (overflow)
              for (final (i, day) in days.indexed)
                if (ofDay(i).length case final n when n > lanes)
                  Positioned(
                    left: i * cell + 2,
                    width: cell - 4,
                    top: _dayNumberHeight + lanes * _laneHeight,
                    height: _laneHeight - 2,
                    child: InkWell(
                      onTap: () => actions.showDay(DateTime(start.year, start.month, start.day + day), ofDay(i)),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t.calendarMore(n - slots.where((s) => s.lane < lanes && s.first <= i && s.last >= i).length),
                          style: TextStyle(fontSize: 11, color: tt.textSecondary),
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.today, required this.month, required this.actions});

  final DateTime day;
  final DateTime today;
  final int? month;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final labels = DateLabels(AppLocalizations.of(context));
    final isToday = day == today;
    final dim = month != null && day.month != month;
    // The 1st of a month carries the month's short name, as in TickTick's month view.
    final number = day.day == 1 ? '${day.day} ${labels.monthShort(day)}' : '${day.day}';
    return CalendarDropArea(
      onDrop: (taskId, _) => actions.move(taskId, day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => actions.create(DateSelection(dueDate: day)),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: tt.divider),
              bottom: BorderSide(color: tt.divider),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 3),
          // No alignment on this box: with one, a Container fills the cell's width.
          child: Container(
            constraints: const BoxConstraints(minWidth: 22),
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: isToday ? BoxDecoration(color: tt.primary, borderRadius: BorderRadius.circular(11)) : null,
            child: Center(
              widthFactor: 1,
              child: Text(
                number,
                style: TextStyle(
                  fontSize: TtText.small,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: isToday ? Colors.white : (dim ? tt.textFaint : tt.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.entry, required this.actions, required this.width, this.days = 1});

  final CalendarEntry entry;
  final CalendarActions actions;
  final double width;

  /// Days the bar spans in this week.
  final int days;

  @override
  Widget build(BuildContext context) {
    final color = actions.colorOf(entry);
    final chip = GestureDetector(
      onTap: () => actions.open(entry, anchor: globalRectOf(context)),
      onSecondaryTapUp: (d) => actions.menu(entry, d.globalPosition),
      // Narrow cells (phones) leave the time out.
      child: CalendarChip(
        entry: entry,
        color: color,
        showTime: width > 90,
        selected: actions.isSelected(entry),
        look: actions.look,
        // As in Google Calendar: timed one-day entries are a dot and text; all-day ones a solid bar.
        dot: !actions.look.classic && !entry.isAllDay && days == 1,
      ),
    );
    if (!entry.isEditable) return chip;
    return calendarDraggable(
      context,
      taskId: entry.id,
      feedback: SizedBox(
        width: width,
        child: CalendarChip(entry: entry, color: color, look: actions.look),
      ),
      child: chip,
    );
  }
}

/// Ano: the twelve months with a mark on the days that have something (a heatmap by the number of
/// entries). A click on a month opens Mês; on a day, Semana.
class CalendarYearView extends StatelessWidget {
  const CalendarYearView({super.key, required this.year, required this.entries, required this.today, required this.onMonth, required this.onDay});

  final int year;
  final List<CalendarEntry> entries;
  final DateTime today;
  final void Function(DateTime month) onMonth;
  final void Function(DateTime day) onDay;

  @override
  Widget build(BuildContext context) {
    final count = <DateTime, int>{};
    for (final e in entries) {
      for (var d = e.firstDay; !d.isAfter(e.lastDay); d = DateTime(d.year, d.month, d.day + 1)) {
        count[d] = (count[d] ?? 0) + 1;
      }
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1000 ? 4 : (box.maxWidth >= 640 ? 3 : 2);
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 20,
          childAspectRatio: 1.05,
          children: [for (var m = 1; m <= 12; m++) _MiniMonth(month: DateTime(year, m), count: count, today: today, onMonth: onMonth, onDay: onDay)],
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({required this.month, required this.count, required this.today, required this.onMonth, required this.onDay});

  final DateTime month;
  final Map<DateTime, int> count;
  final DateTime today;
  final void Function(DateTime month) onMonth;
  final void Function(DateTime day) onDay;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final labels = DateLabels(AppLocalizations.of(context));
    final start = weekStartOf(month);
    final name = labels.monthLong(month);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => onMonth(month),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${name[0].toUpperCase()}${name.substring(1)}',
              style: TextStyle(
                fontSize: TtText.body,
                fontWeight: FontWeight.w600,
                color: month.month == today.month && month.year == today.year ? tt.primary : tt.text,
              ),
            ),
          ),
        ),
        CalendarWeekdayHeader(from: start),
        Expanded(
          child: Column(
            children: [
              for (var w = 0; w < 6; w++)
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final day = DateTime(start.year, start.month, start.day + 7 * w + i);
                              if (day.month != month.month) return const SizedBox.shrink();
                              final n = count[day] ?? 0;
                              final isToday = day == today;
                              return InkWell(
                                onTap: () => onDay(day),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isToday ? tt.primary : (n == 0 ? null : tt.primary.withValues(alpha: math.min(0.15 + 0.15 * n, 0.6))),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('${day.day}', style: TextStyle(fontSize: 11, color: isToday ? Colors.white : tt.textSecondary)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Agenda: the days that have something, in a scrolling list.
class CalendarAgenda extends ConsumerWidget {
  const CalendarAgenda({super.key, required this.from, required this.days, required this.entries, required this.today, required this.actions});

  final DateTime from;
  final int days;
  final List<CalendarEntry> entries;
  final DateTime today;
  final CalendarActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final byDay = <(DateTime, List<CalendarEntry>)>[
      for (var i = 0; i < days; i++)
        if (DateTime(from.year, from.month, from.day + i) case final day)
          if (entries.where((e) => e.touches(day)).toList() case final list when list.isNotEmpty) (day, list),
    ];
    if (byDay.isEmpty) {
      return Center(
        child: Text(t.calendarAgendaEmpty, style: TextStyle(color: tt.textTertiary)),
      );
    }
    final now = ref.watch(clockProvider).now();
    // Phones: narrower day and time columns, so the titles keep room.
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    // "(Dia 1/2)": an entry that spans days says which of its days this is (Google's Schedule).
    String? part(CalendarEntry e, DateTime day) {
      if (e.isAllDay) return null;
      final first = startOfDay(e.start);
      final last = startOfDay(e.end.subtract(const Duration(microseconds: 1)));
      final total = daysBetween(first, last) + 1;
      return total > 1 ? t.calendarDayOfTotal(daysBetween(first, day) + 1, total) : null;
    }

    Widget item(CalendarEntry e, DateTime day) {
      final title = e.title.isEmpty ? (e.kind == CalendarEntryKind.focus ? t.calendarFocusRecord : t.untitled) : e.title;
      final faded = actions.look.faded(e);
      final suffix = part(e, day);
      return InkWell(
        onTap: () => actions.open(e),
        onSecondaryTapUp: (d) => actions.menu(e, d.globalPosition),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: actions.look.fill(actions.colorOf(e), done: faded, screen: tt.screen),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: narrow ? 8 : 14),
              SizedBox(
                width: narrow ? 84 : 118,
                child: Text(
                  e.isAllDay
                      ? t.calendarAllDay
                      : (e.task?.hasDuration == false ? DateLabels.time(e.start) : '${DateLabels.time(e.start)} – ${DateLabels.time(e.end)}'),
                  style: TextStyle(fontSize: TtText.small, color: faded ? tt.textTertiary : tt.textSecondary),
                ),
              ),
              if (e.kind == CalendarEntryKind.task && e.task != null && !e.isOccurrence) ...[
                TaskCheckbox(
                  status: e.task!.status,
                  priority: e.task!.priority,
                  kind: e.task!.kind,
                  onTap: () => unawaited(toggleComplete(context, ref, e.task!)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  suffix == null ? title : '$title $suffix',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TtText.body,
                    fontWeight: FontWeight.w600,
                    color: faded ? tt.textTertiary : tt.text,
                    decoration: e.isDone && e.task?.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // The red line of "now", between today's entries, as in Google's Schedule.
    Widget nowLine() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 2, color: const Color(0xFFEA4335))),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        for (final (i, (day, list)) in byDay.indexed) ...[
          if (i > 0) Divider(height: 1, color: tt.divider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The day: its number (today in a filled circle) and "SET, SEX".
                SizedBox(
                  width: narrow ? 92 : 112,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: day == today ? BoxDecoration(color: tt.primary, shape: BoxShape.circle) : null,
                        child: Text('${day.day}', style: TextStyle(fontSize: 20, color: day == today ? Colors.white : tt.text)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${labels.monthShort(day)}, ${labels.weekdayShort(day)}'.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w600,
                          color: day == today ? tt.primary : tt.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (j, e) in list.indexed) ...[
                        if (day == today &&
                            !e.isAllDay &&
                            !e.start.isBefore(now) &&
                            (j == 0 || list[j - 1].isAllDay || list[j - 1].start.isBefore(now)))
                          nowLine(),
                        item(e, day),
                      ],
                      if (day == today && list.every((e) => e.isAllDay || e.start.isBefore(now))) nowLine(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
