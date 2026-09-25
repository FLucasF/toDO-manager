import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/time_zones.dart';
import '../../domain/calendar.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';
import 'calendar_widgets.dart';

const _hourHeight = 48.0;
const _collapsedHeight = 28.0;
const _gutter = 56.0;

/// Width of each "Fuso adicional" column left of the hours.
const _zoneWidth = 46.0;
const _laneHeight = 20.0;
const _maxBandLanes = 4;

/// Hidden ranges of the timeline: 00:00-07:00 and 21:00-24:00.
const _defaultEarlyEnd = 7 * 60;
const _defaultLateStart = 21 * 60;
const _dayMinutes = 24 * 60;

/// Vertical scale of the timeline: minutes of the day ↔ pixels, with the hidden ranges squeezed.
class _Scale {
  const _Scale({
    required this.early,
    required this.late,
    this.hour = _hourHeight,
    this.earlyEnd = _defaultEarlyEnd,
    this.lateStart = _defaultLateStart,
  });

  /// Whether each hidden range is collapsed.
  final bool early;
  final bool late;

  /// Minutes where the early range ends and the late one starts (Opções de visualização).
  final int earlyEnd;
  final int lateStart;

  /// Height of one hour outside the hidden ranges.
  final double hour;

  double get earlyHeight => early ? _collapsedHeight : earlyEnd / 60 * hour;
  double get middleHeight => (lateStart - earlyEnd) / 60 * hour;
  double get lateHeight => late ? _collapsedHeight : (_dayMinutes - lateStart) / 60 * hour;
  double get total => earlyHeight + middleHeight + lateHeight;

  double y(num minutes) {
    if (minutes <= earlyEnd) return early ? minutes / earlyEnd * _collapsedHeight : minutes / 60 * hour;
    if (minutes <= lateStart) return earlyHeight + (minutes - earlyEnd) / 60 * hour;
    final past = minutes - lateStart;
    return earlyHeight + middleHeight + (late ? past / (_dayMinutes - lateStart) * _collapsedHeight : past / 60 * hour);
  }

  int minutesAt(double y) {
    final double minutes;
    if (y <= earlyHeight) {
      minutes = early ? y / _collapsedHeight * earlyEnd : y / hour * 60;
    } else if (y <= earlyHeight + middleHeight) {
      minutes = earlyEnd + (y - earlyHeight) / hour * 60;
    } else {
      final past = y - earlyHeight - middleHeight;
      minutes = lateStart + (late ? past / _collapsedHeight * (_dayMinutes - lateStart) : past / hour * 60);
    }
    return minutes.round().clamp(0, _dayMinutes);
  }
}

int _minuteOfDay(DateTime d, DateTime day) => d.difference(day).inMinutes.clamp(0, _dayMinutes);

DateTime _at(DateTime day, int minutes) => DateTime(day.year, day.month, day.day, 0, minutes);

int _snap(int minutes, int step) => (minutes / step).round() * step;

/// A piece of a timed entry inside one day.
class _Piece {
  _Piece(this.entry, this.day, this.dayIndex, this.startMin, this.endMin);

  final CalendarEntry entry;
  final DateTime day;
  final int dayIndex;
  final int startMin;
  final int endMin;

  /// Whether the entry really ends in this piece (its bottom edge can be dragged).
  bool get holdsEnd => _at(day, endMin) == entry.end || entry.end.isBefore(_at(day, endMin));
}

/// Dia, Semana and Multi-Dia: the "Dia inteiro" band on top and a timeline of
/// hours. A click on the timeline creates a task at that time and a drag creates one with a duration;
/// a block is moved by dragging it and resized by its bottom edge.
class CalendarTimeline extends StatefulWidget {
  const CalendarTimeline({
    super.key,
    required this.from,
    required this.days,
    this.hideWeekends = false,
    required this.entries,
    required this.today,
    required this.now,
    required this.actions,
    this.zones = const [],
    this.hiddenBefore = 7,
    this.hiddenAfter = 21,
    this.minMinutes = 0,
  });

  final DateTime from;
  final int days;
  final List<CalendarEntry> entries;
  final DateTime today;
  final DateTime now;
  final CalendarActions actions;

  /// "Fusos adicionais" (IANA ids): their hours in columns left of the local ones.
  final List<String> zones;

  /// The hidden ranges: before [hiddenBefore] and from [hiddenAfter] (hours).
  final int hiddenBefore;
  final int hiddenAfter;

  /// "Mostrar fins de semana" off: Saturday and Sunday are left out of the columns.
  final bool hideWeekends;

  /// Blocks are at least this tall, in minutes ("Eventos curtos com o tamanho de 30 minutos").
  final int minMinutes;

  @override
  State<CalendarTimeline> createState() => _CalendarTimelineState();
}

class _CalendarTimelineState extends State<CalendarTimeline> {
  bool _earlyOpen = false;
  bool _lateOpen = false;

  /// Lanes the "Dia inteiro" band shows before "+N"; its lower edge drags.
  int _bandLanes = _maxBandLanes;
  double _bandDrag = 0;

  /// Ctrl + wheel zooms the hours.
  double _zoom = 1;
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// The columns: every day of the period, or only the weekdays when weekends are hidden (all of
  /// them again if nothing would be left).
  List<DateTime> get _dates {
    final all = [for (var i = 0; i < widget.days; i++) DateTime(widget.from.year, widget.from.month, widget.from.day + i)];
    if (!widget.hideWeekends) return all;
    final weekdays = all.where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday).toList();
    return weekdays.isEmpty ? all : weekdays;
  }

  DateTime _day(int i) => _dates[i];

  List<_Piece> _pieces() {
    final pieces = <_Piece>[];
    for (final e in widget.entries.where((e) => !e.isAllDay)) {
      for (var i = 0; i < _dates.length; i++) {
        final day = _day(i);
        if (!e.touches(day)) continue;
        final next = DateTime(day.year, day.month, day.day + 1);
        final start = e.start.isBefore(day) ? 0 : _minuteOfDay(e.start, day);
        final end = e.end.isAfter(next) ? _dayMinutes : _minuteOfDay(e.end, day);
        pieces.add(_Piece(e, day, i, start, math.max(end, start + 1)));
      }
    }
    return pieces;
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final pieces = _pieces();
    // A hidden range opens by itself when something is inside it.
    final earlyEnd = widget.hiddenBefore.clamp(0, 12) * 60;
    final lateStart = math.max(widget.hiddenAfter.clamp(12, 24) * 60, earlyEnd + 60);
    final early = earlyEnd > 0 && !_earlyOpen && !pieces.any((p) => p.startMin < earlyEnd);
    final late = lateStart < _dayMinutes && !_lateOpen && !pieces.any((p) => p.endMin > lateStart);
    final zones = [
      for (final id in widget.zones)
        if (findZone(id) != null) id,
    ];
    final gutter = _gutter + zones.length * _zoneWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayHeaders(dates: _dates, today: widget.today, gutter: gutter, zones: zones),
        _AllDayBand(
          dates: _dates,
          entries: widget.entries.where((e) => e.isAllDay).toList(),
          actions: widget.actions,
          gutter: gutter,
          maxLanes: _bandLanes,
        ),
        // The band's lower edge: drag to show more or fewer lanes.
        MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) {
              _bandDrag += d.delta.dy;
              final steps = (_bandDrag / _laneHeight).truncate();
              if (steps != 0) {
                _bandDrag -= steps * _laneHeight;
                setState(() => _bandLanes = (_bandLanes + steps).clamp(1, 12));
              }
            },
            onVerticalDragEnd: (_) => _bandDrag = 0,
            child: SizedBox(
              height: 5,
              child: Center(child: Divider(height: 1, color: tt.divider)),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, viewport) {
              // The hours stretch to fill the window, never below 48 px.
              final hours = (lateStart - earlyEnd) / 60 + (early ? 0 : earlyEnd / 60) + (late ? 0 : (_dayMinutes - lateStart) / 60);
              final squeezed = (early ? _collapsedHeight : 0) + (late ? _collapsedHeight : 0);
              final scale = _Scale(
                early: early,
                late: late,
                hour: math.max(_hourHeight, (viewport.maxHeight - squeezed) / hours) * _zoom,
                earlyEnd: earlyEnd,
                lateStart: lateStart,
              );
              _scroll ??= ScrollController(initialScrollOffset: early ? 0 : scale.y(earlyEnd) - 8);
              return SingleChildScrollView(
                controller: _scroll,
                // Inside the scroll view, so Ctrl + wheel is claimed before the view scrolls.
                child: Listener(
                  onPointerSignal: (e) {
                    if (e is! PointerScrollEvent || !HardwareKeyboard.instance.isControlPressed) return;
                    GestureBinding.instance.pointerSignalResolver.register(e, (_) {
                      setState(() => _zoom = (_zoom * (e.scrollDelta.dy < 0 ? 1.15 : 1 / 1.15)).clamp(0.6, 3.0));
                    });
                  },
                  child: SizedBox(
                    height: scale.total,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final zone in zones)
                          SizedBox(
                            width: _zoneWidth,
                            child: _ZoneHourLabels(scale: scale, day: widget.from, zone: zone),
                          ),
                        SizedBox(
                          width: _gutter,
                          child: _HourLabels(
                            scale: scale,
                            noon: t.calendarNoon,
                            earlyOpen: _earlyOpen,
                            lateOpen: _lateOpen,
                            onEarly: () => setState(() => _earlyOpen = !_earlyOpen),
                            onLate: () => setState(() => _lateOpen = !_lateOpen),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final dates = _dates;
                              final column = box.maxWidth / dates.length;
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _GridPainter(scale: scale, days: dates.length, line: tt.divider, band: tt.hover),
                                    ),
                                  ),
                                  for (var i = 0; i < dates.length; i++)
                                    Positioned(
                                      left: i * column,
                                      width: column,
                                      top: 0,
                                      bottom: 0,
                                      child: _DayColumn(day: _day(i), scale: scale, actions: widget.actions),
                                    ),
                                  for (var i = 0; i < dates.length; i++)
                                    for (final slot in layoutTimeline([
                                      for (final p in pieces.where((p) => p.dayIndex == i))
                                        CalendarEntry(
                                          kind: p.entry.kind,
                                          id: '${pieces.indexOf(p)}',
                                          title: p.entry.title,
                                          start: _at(p.day, p.startMin),
                                          end: _at(p.day, math.max(p.endMin, p.startMin + widget.minMinutes)),
                                          isAllDay: false,
                                        ),
                                    ]))
                                      if (pieces[int.parse(slot.entry.id)] case final p)
                                        Positioned(
                                          left: i * column + slot.column * column / slot.columns + 1,
                                          width: column / slot.columns - 2,
                                          top: scale.y(p.startMin),
                                          height: math.max(
                                            scale.y(math.min(24 * 60, math.max(p.endMin, p.startMin + widget.minMinutes))) - scale.y(p.startMin),
                                            18,
                                          ),
                                          child: _Block(piece: p, scale: scale, columnWidth: column, actions: widget.actions),
                                        ),
                                  if (dates.contains(widget.today))
                                    Positioned(
                                      left: dates.indexOf(widget.today) * column,
                                      width: column,
                                      top: scale.y(_minuteOfDay(widget.now, widget.today)) - 4,
                                      height: 8,
                                      child: IgnorePointer(child: _NowLine(color: tt.palette.priorityHigh)),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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

class _DayHeaders extends StatelessWidget {
  const _DayHeaders({required this.dates, required this.today, required this.gutter, required this.zones});

  final List<DateTime> dates;
  final DateTime today;
  final double gutter;
  final List<String> zones;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final labels = DateLabels(AppLocalizations.of(context));
    final zoneStyle = TextStyle(fontSize: 9, color: tt.textTertiary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Each column of hours says its offset; the city is in the tooltip.
          SizedBox(
            width: gutter,
            child: zones.isEmpty
                ? null
                : Row(
                    children: [
                      for (final zone in zones)
                        SizedBox(
                          width: _zoneWidth,
                          child: Tooltip(
                            message: zoneCity(zone),
                            child: Text(zoneOffsetLabel(zone, dates.first), textAlign: TextAlign.center, style: zoneStyle),
                          ),
                        ),
                      SizedBox(
                        width: _gutter,
                        child: Text(localOffsetLabel(dates.first), textAlign: TextAlign.center, style: zoneStyle),
                      ),
                    ],
                  ),
          ),
          for (final day in dates)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels.weekdayShort(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                      color: day == today ? tt.primary : tt.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: day == today ? BoxDecoration(color: tt.primary, shape: BoxShape.circle) : null,
                    child: Text('${day.day}', style: TextStyle(fontSize: 20, color: day == today ? Colors.white : tt.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Dia inteiro" band: all-day entries as bars; a click creates an all-day task; a task dropped
/// here loses its time.
class _AllDayBand extends StatelessWidget {
  const _AllDayBand({required this.dates, required this.entries, required this.actions, required this.gutter, this.maxLanes = _maxBandLanes});

  /// The visible days (weekends may be left out).
  final List<DateTime> dates;
  final List<CalendarEntry> entries;
  final CalendarActions actions;
  final double gutter;

  /// Lanes before "+N" (at least 1).
  final int maxLanes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final from = dates.first;
    final days = daysBetween(from, dates.last) + 1;
    // Spans over every day of the period, then moved onto the visible columns.
    final slots = [
      for (final s in layoutSpans(entries, from, days))
        if (_columns(s.first, s.last) case (final first, final last)) (entry: s.entry, lane: s.lane, first: first, last: last),
    ];
    final used = slots.isEmpty ? 1 : slots.map((s) => s.lane).reduce(math.max) + 1;
    final overflow = used > maxLanes;
    final lanes = overflow ? maxLanes - 1 : used;
    final height = (overflow ? maxLanes : used) * _laneHeight + 6;
    DateTime day(int i) => dates[i];
    final columns = dates.length;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: gutter,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: Text(
                t.calendarAllDay,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: tt.textTertiary),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final column = box.maxWidth / columns;
                return Stack(
                  children: [
                    for (var i = 0; i < columns; i++)
                      Positioned(
                        left: i * column,
                        width: column,
                        top: 0,
                        bottom: 0,
                        child: CalendarDropArea(
                          onDrop: (taskId, _) => actions.move(taskId, day(i)),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => actions.create(DateSelection(dueDate: day(i))),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: tt.divider)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final s in slots)
                      if (s.lane < lanes)
                        Positioned(
                          left: s.first * column + 2,
                          width: (s.last - s.first + 1) * column - 4,
                          top: 3 + s.lane * _laneHeight,
                          height: _laneHeight - 2,
                          child: _BandBar(entry: s.entry, actions: actions, width: column - 4),
                        ),
                    if (overflow)
                      for (var i = 0; i < columns; i++)
                        if (slots.where((s) => s.first <= i && s.last >= i).toList() case final ofDay when ofDay.any((s) => s.lane >= lanes))
                          Positioned(
                            left: i * column + 2,
                            width: column - 4,
                            top: 3 + lanes * _laneHeight,
                            height: _laneHeight - 2,
                            child: InkWell(
                              onTap: () => actions.showDay(day(i), [for (final s in ofDay) s.entry]),
                              child: Text(
                                t.calendarMore(ofDay.where((s) => s.lane >= lanes).length),
                                style: TextStyle(fontSize: 11, color: tt.textSecondary),
                              ),
                            ),
                          ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// A span's first and last day (indexes in the period) as visible columns; null when all are hidden.
  (int, int)? _columns(int first, int last) {
    final from = dates.first;
    final shown = [
      for (var c = 0; c < dates.length; c++)
        if (daysBetween(from, dates[c]) case final i when i >= first && i <= last) c,
    ];
    return shown.isEmpty ? null : (shown.first, shown.last);
  }
}

class _BandBar extends StatelessWidget {
  const _BandBar({required this.entry, required this.actions, required this.width});

  final CalendarEntry entry;
  final CalendarActions actions;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = actions.colorOf(entry);
    final chip = GestureDetector(
      onTap: () => actions.open(entry, anchor: globalRectOf(context)),
      onSecondaryTapUp: (d) => actions.menu(entry, d.globalPosition),
      child: CalendarChip(entry: entry, color: color, selected: actions.isSelected(entry), look: actions.look),
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

class _HourLabels extends StatelessWidget {
  const _HourLabels({
    required this.scale,
    required this.noon,
    required this.earlyOpen,
    required this.lateOpen,
    required this.onEarly,
    required this.onLate,
  });

  final _Scale scale;
  final String noon;
  final bool earlyOpen;
  final bool lateOpen;
  final VoidCallback onEarly;
  final VoidCallback onLate;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final style = TextStyle(fontSize: 10, color: tt.textTertiary);
    String hour(int h) => h == 12 ? noon : DateLabels.time(DateTime(2000, 1, 1, h));
    Widget range(String text, double top, VoidCallback onTap) => Positioned(
      top: top,
      left: 0,
      right: 0,
      height: _collapsedHeight,
      child: InkWell(
        onTap: onTap,
        // "00:00 - 07:00" is a little wider than the column: it shrinks to fit instead of being cut.
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, maxLines: 1, style: style.copyWith(fontSize: 9)),
            ),
          ),
        ),
      ),
    );
    Widget fold(double top, VoidCallback onTap) => Positioned(
      top: top,
      left: 0,
      child: InkWell(
        onTap: onTap,
        child: Icon(Icons.unfold_less, size: 14, color: tt.textTertiary),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (scale.early)
          range('${DateLabels.time(DateTime(2000))} - ${DateLabels.time(DateTime(2000, 1, 1, scale.earlyEnd ~/ 60))}', 0, onEarly)
        else if (earlyOpen)
          fold(2, onEarly),
        if (scale.late)
          range(
            '${DateLabels.time(DateTime(2000, 1, 1, scale.lateStart ~/ 60))} - ${DateLabels.time(DateTime(2000))}',
            scale.y(scale.lateStart),
            onLate,
          )
        else if (lateOpen)
          fold(scale.y(scale.lateStart) + 2, onLate),
        for (var h = 1; h < 24; h++)
          if (!(scale.early && h * 60 <= scale.earlyEnd) && !(scale.late && h * 60 >= scale.lateStart))
            Positioned(
              top: scale.y(h * 60) - 7,
              right: 6,
              child: Text(hour(h), style: style),
            ),
      ],
    );
  }
}

/// The hours of a "Fuso adicional": what the clock there says at each local hour of [day].
class _ZoneHourLabels extends StatelessWidget {
  const _ZoneHourLabels({required this.scale, required this.day, required this.zone});

  final _Scale scale;
  final DateTime day;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 10, color: context.tt.textTertiary);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var h = 1; h < 24; h++)
          if (!(scale.early && h * 60 <= scale.earlyEnd) && !(scale.late && h * 60 >= scale.lateStart))
            if (zoneTime(DateTime(day.year, day.month, day.day, h), zone) case final there?)
              Positioned(
                top: scale.y(h * 60) - 7,
                right: 6,
                child: Text(DateLabels.time(DateTime(2000, 1, 1, there.hour, there.minute)), style: style),
              ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.scale, required this.days, required this.line, required this.band});

  final _Scale scale;
  final int days;
  final Color line;
  final Color band;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    final fill = Paint()..color = band;
    if (scale.early) canvas.drawRect(Rect.fromLTWH(0, 0, size.width, scale.earlyHeight), fill);
    if (scale.late) canvas.drawRect(Rect.fromLTWH(0, scale.y(scale.lateStart), size.width, scale.lateHeight), fill);
    for (var h = 1; h < 24; h++) {
      if (scale.early && h < 7 || scale.late && h > 21) continue;
      final y = scale.y(h * 60);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var i = 0; i < days; i++) {
      final x = i * size.width / days;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.scale.early != scale.early || old.scale.late != scale.late || old.scale.hour != scale.hour || old.days != days || old.line != line;
}

/// One day of the timeline: click → task at that time; drag → task with that duration; drop → the
/// task moves to that time.
class _DayColumn extends StatefulWidget {
  const _DayColumn({required this.day, required this.scale, required this.actions});

  final DateTime day;
  final _Scale scale;
  final CalendarActions actions;

  @override
  State<_DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends State<_DayColumn> {
  double? _from;
  double? _to;

  int _minutes(double y, {int step = 15}) => _snap(widget.scale.minutesAt(y), step).clamp(0, _dayMinutes);

  void _create(int start, int end) {
    final day = widget.day;
    if (end - start < 15) {
      widget.actions.create(DateSelection(dueDate: _at(day, start), isAllDay: false));
    } else {
      widget.actions.create(DateSelection(startDate: _at(day, start), dueDate: _at(day, end), isAllDay: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final from = _from, to = _to;
    return CalendarDropArea(
      onDrop: (taskId, global) {
        final box = context.findRenderObject()! as RenderBox;
        final y = box.globalToLocal(global).dy;
        widget.actions.move(taskId, widget.day, time: _at(widget.day, _minutes(y)));
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          // A click takes the half hour it falls in.
          final start = (widget.scale.minutesAt(d.localPosition.dy) ~/ 30) * 30;
          _create(start, start);
        },
        // The task starts where the button went down, not where the drag was recognized.
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (d) => setState(() => _from = _to = d.localPosition.dy),
        onPanUpdate: (d) => setState(() => _to = d.localPosition.dy),
        onPanEnd: (_) {
          final a = _from, b = _to;
          setState(() => _from = _to = null);
          if (a == null || b == null) return;
          final start = _minutes(math.min(a, b)), end = _minutes(math.max(a, b));
          _create(start, end);
        },
        onPanCancel: () => setState(() => _from = _to = null),
        child: Stack(
          children: [
            if (from != null && to != null)
              Positioned(
                left: 2,
                right: 2,
                top: widget.scale.y(_minutes(math.min(from, to))),
                height: math.max(widget.scale.y(_minutes(math.max(from, to))) - widget.scale.y(_minutes(math.min(from, to))), 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: tt.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tt.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A timed entry on the timeline: title and "09:00-12:00"; dragged to move, bottom edge to resize.
class _Block extends StatefulWidget {
  const _Block({required this.piece, required this.scale, required this.columnWidth, required this.actions});

  final _Piece piece;
  final _Scale scale;
  final double columnWidth;
  final CalendarActions actions;

  @override
  State<_Block> createState() => _BlockState();
}

class _BlockState extends State<_Block> {
  Offset _move = Offset.zero;
  double _resize = 0;
  bool _moving = false;

  _Piece get _p => widget.piece;

  void _endMove() {
    final delta = _move;
    setState(() {
      _move = Offset.zero;
      _moving = false;
    });
    if (delta.distance < 4) return;
    final newStart = _snap(widget.scale.minutesAt(widget.scale.y(_p.startMin) + delta.dy), 15);
    final dayShift = (delta.dx / widget.columnWidth).round();
    final shift = Duration(minutes: newStart - _p.startMin + dayShift * _dayMinutes);
    final start = _p.entry.start.add(shift);
    widget.actions.move(_p.entry.id, startOfDay(start), time: start);
  }

  void _endResize() {
    final dy = _resize;
    setState(() => _resize = 0);
    final task = _p.entry.task;
    if (task == null || dy.abs() < 2) return;
    final end = _snap(widget.scale.minutesAt(widget.scale.y(_p.endMin) + dy), 15);
    final newEnd = _at(_p.day, end);
    if (!newEnd.isAfter(_p.entry.start.add(const Duration(minutes: 14)))) return;
    widget.actions.resize(task, newEnd);
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final e = _p.entry;
    final color = widget.actions.colorOf(e);
    final height = math.max(widget.scale.y(_p.endMin) - widget.scale.y(_p.startMin), 18.0);
    final title = e.title.isEmpty
        ? (e.kind == CalendarEntryKind.focus ? AppLocalizations.of(context).calendarFocusRecord : AppLocalizations.of(context).untitled)
        : e.title;
    final look = widget.actions.look;
    final ink = look.ink(color, done: look.faded(e), tt: tt);
    final time = e.task?.hasDuration == false ? DateLabels.time(e.start) : '${DateLabels.time(e.start)} – ${DateLabels.time(e.end)}';
    // Short blocks put the time after the title, on one line.
    final oneLine = height < 34;
    final body = Container(
      // Google Calendar's gap: the column's edge stays free to click, and stacked blocks don't touch.
      margin: const EdgeInsets.only(right: 6, bottom: 1),
      // The shortest blocks (a few minutes) drop the vertical padding, so the line fits.
      padding: EdgeInsets.fromLTRB(6, height < 22 ? 0 : 3, 4, height < 22 ? 0 : 2),
      decoration: BoxDecoration(
        color: look.fill(color, done: look.faded(e), screen: tt.screen),
        borderRadius: BorderRadius.circular(6),
        border: widget.actions.isSelected(e) ? Border.all(color: tt.text, width: 2) : null,
        boxShadow: _moving ? const [BoxShadow(blurRadius: 8, color: Colors.black38)] : null,
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (look.icons)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Icon(calendarEntryIcon(e), size: 11, color: ink),
                      ),
                    ),
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (oneLine) TextSpan(text: ', $time'),
                ],
              ),
              maxLines: oneLine ? 1 : (height > 52 ? 2 : 1),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: ink,
                decoration: e.isDone && e.kind == CalendarEntryKind.task ? TextDecoration.lineThrough : null,
              ),
            ),
            if (!oneLine)
              Text(
                time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.25, color: ink.withValues(alpha: 0.85)),
              ),
          ],
        ),
      ),
    );
    if (!e.isEditable) {
      return GestureDetector(
        onTap: () => widget.actions.open(e, anchor: globalRectOf(context)),
        onSecondaryTapUp: (d) => widget.actions.menu(e, d.globalPosition),
        child: body,
      );
    }
    return Transform.translate(
      offset: _move,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: -_resize,
            child: MouseRegion(
              cursor: _moving ? SystemMouseCursors.grabbing : SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget.actions.open(e, anchor: globalRectOf(context)),
                onSecondaryTapUp: (d) => widget.actions.menu(e, d.globalPosition),
                // The first update then carries the whole distance from the press.
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (_) => setState(() => _moving = true),
                onPanUpdate: (d) => setState(() => _move += d.delta),
                onPanEnd: (_) => _endMove(),
                onPanCancel: () => setState(() {
                  _move = Offset.zero;
                  _moving = false;
                }),
                child: body,
              ),
            ),
          ),
          if (_p.holdsEnd)
            Positioned(
              left: 0,
              right: 0,
              bottom: -_resize - 3,
              height: 8,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onVerticalDragUpdate: (d) => setState(() => _resize += d.delta.dy),
                  onVerticalDragEnd: (_) => _endResize(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(left: 0, right: 0, top: 3, height: 2, child: ColoredBox(color: color)),
      Positioned(
        left: -1,
        top: 0,
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    ],
  );
}
