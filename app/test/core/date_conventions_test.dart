import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/format/date_labels.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/domain/calendar.dart';
import 'package:task_manager/domain/statistics.dart';

void main() {
  tearDown(() {
    DateConventions.firstWeekday = DateTime.sunday;
    DateConventions.use24h = true;
    DateConventions.weekNumbers = false;
  });

  // Friday, 2026-09-25.
  final friday = DateTime(2026, 9, 25, 15);

  test('the week starts on the chosen day everywhere', () {
    expect(startOfWeek(friday), DateTime(2026, 9, 20));
    expect(weekdayOrder(), [7, 1, 2, 3, 4, 5, 6]);
    DateConventions.firstWeekday = DateTime.monday;
    expect(startOfWeek(friday), DateTime(2026, 9, 21));
    expect(startOfWeek(DateTime(2026, 9, 20)), DateTime(2026, 9, 14), reason: 'a Sunday belongs to the week that began on Monday');
    expect(weekdayOrder(), [1, 2, 3, 4, 5, 6, 7]);
    expect(calendarPeriod(CalendarMode.week, friday, const CalendarOptions()).from, DateTime(2026, 9, 21));
    expect(periodStart(StatsPeriod.week, friday), DateTime(2026, 9, 21));
    DateConventions.firstWeekday = DateTime.saturday;
    expect(startOfWeek(friday), DateTime(2026, 9, 19));
    expect(weekdayOrder().first, DateTime.saturday);
    // Any day can start the week.
    DateConventions.firstWeekday = DateTime.wednesday;
    expect(startOfWeek(friday), DateTime(2026, 9, 23));
    expect(weekdayOrder(), [3, 4, 5, 6, 7, 1, 2]);
  });

  test('12-hour times and ISO week numbers', () {
    expect(DateLabels.time(DateTime(2026, 9, 25, 13, 5)), '13:05');
    DateConventions.use24h = false;
    expect(DateLabels.time(DateTime(2026, 9, 25, 13, 5)), '1:05 PM');
    expect(DateLabels.time(DateTime(2026, 9, 25, 0, 30)), '12:30 AM');
    expect(DateLabels.time(DateTime(2026, 9, 25, 12)), '12:00 PM');
    expect(isoWeekNumber(friday), 39);
    expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
    expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
  });
}
