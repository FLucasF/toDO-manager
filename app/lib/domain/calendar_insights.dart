import 'dart:math' as math;

import '../core/clock.dart';
import 'calendar.dart';
import 'task_dates.dart';

/// One part of the time breakdown: what [key] names (a list, a tag, a kind) and its time.
typedef InsightSlice = ({String key, Duration time});

/// Time Insights: the scheduled time of the period [from] + [days],
/// split by [keyOf] (null leaves an entry out) and by day. All-day entries and entries without a length
/// of their own (drawn at the default size) don't count, as in Google Calendar; each entry counts only
/// inside the period.
({List<InsightSlice> slices, List<Duration> perDay, Duration total}) timeInsights(
  Iterable<CalendarEntry> entries,
  DateTime from,
  int days,
  String? Function(CalendarEntry entry) keyOf,
) {
  final byKey = <String, Duration>{};
  final perDay = List.filled(days, Duration.zero);
  for (final e in entries) {
    if (e.isAllDay || !e.end.isAfter(e.start) || !_hasLength(e)) continue;
    final key = keyOf(e);
    if (key == null) continue;
    for (var i = 0; i < days; i++) {
      final dayStart = DateTime(from.year, from.month, from.day + i);
      final dayEnd = DateTime(from.year, from.month, from.day + i + 1);
      final start = DateTime.fromMillisecondsSinceEpoch(math.max(e.start.millisecondsSinceEpoch, dayStart.millisecondsSinceEpoch));
      final end = DateTime.fromMillisecondsSinceEpoch(math.min(e.end.millisecondsSinceEpoch, dayEnd.millisecondsSinceEpoch));
      if (!end.isAfter(start)) continue;
      final part = end.difference(start);
      perDay[i] += part;
      byKey[key] = (byKey[key] ?? Duration.zero) + part;
    }
  }
  final slices = [for (final e in byKey.entries) (key: e.key, time: e.value)]..sort((a, b) => b.time.compareTo(a.time));
  return (slices: slices, perDay: perDay, total: perDay.fold(Duration.zero, (a, b) => a + b));
}

/// A task at a point in time (and a checklist item) is drawn at the default size, but has no length.
bool _hasLength(CalendarEntry e) => switch (e.kind) {
  CalendarEntryKind.checklistItem => false,
  CalendarEntryKind.task => e.task == null || e.task!.endLocal!.isAfter(e.task!.startLocal!),
  _ => true,
};

/// "2,5 h", "45 min", "0 h": the hours of a slice.
String insightHours(Duration d) {
  if (d.inMinutes < 60) return d == Duration.zero ? '0 h' : '${d.inMinutes} min';
  final hours = d.inMinutes / 60;
  final text = hours == hours.roundToDouble() ? hours.round().toString() : hours.toStringAsFixed(1).replaceAll('.', ',');
  return '$text h';
}

/// The first day of [period] as a calendar day (the insights start at midnight).
DateTime insightsStart(DateTime from) => startOfDay(from);
