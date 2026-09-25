import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/calendar.dart';
import 'package:task_manager/domain/calendar_insights.dart';

CalendarEntry entry(String id, DateTime start, DateTime end, {bool allDay = false}) =>
    CalendarEntry(kind: CalendarEntryKind.task, id: id, title: id, start: start, end: end, isAllDay: allDay);

void main() {
  test('time insights: hours by key and by day, clipped to the period; all-day and pointless entries left out', () {
    final from = DateTime(2026, 9, 20);
    final entries = [
      entry('trabalho', DateTime(2026, 9, 21, 9), DateTime(2026, 9, 21, 12)),
      entry('trabalho', DateTime(2026, 9, 22, 13), DateTime(2026, 9, 22, 14, 30)),
      entry('casa', DateTime(2026, 9, 22, 23), DateTime(2026, 9, 23, 1)), // crosses midnight
      entry('casa', DateTime(2026, 9, 26, 23), DateTime(2026, 9, 27, 2)), // leaves the week
      entry('ferias', DateTime(2026, 9, 24), DateTime(2026, 9, 25), allDay: true),
      entry('lembrete', DateTime(2026, 9, 24, 8), DateTime(2026, 9, 24, 8)),
    ];
    final r = timeInsights(entries, from, 7, (e) => e.id);
    expect(r.slices, [(key: 'trabalho', time: const Duration(hours: 4, minutes: 30)), (key: 'casa', time: const Duration(hours: 3))]);
    expect(r.perDay.map((d) => d.inMinutes), [0, 180, 90 + 60, 60, 0, 0, 60]);
    expect(r.total, const Duration(hours: 7, minutes: 30));
    expect(
      [insightHours(const Duration(minutes: 45)), insightHours(const Duration(hours: 2, minutes: 30)), insightHours(const Duration(hours: 3))],
      ['45 min', '2,5 h', '3 h'],
    );
  });
}
