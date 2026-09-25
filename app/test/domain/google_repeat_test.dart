import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/recurrence.dart';
import 'package:task_manager/domain/custom_repeat.dart';

void main() {
  test('Google\'s monthly choices: the 4th Friday and the last Friday of each month', () {
    // Friday, 25 September 2026: the 4th Friday and also the last one of the month.
    final day = DateTime(2026, 9, 25, 15);
    expect(weekdayInMonth(day), (nth: 4, last: true));
    expect(weekdayInMonth(DateTime(2026, 9, 4)), (nth: 1, last: false));

    final fourth = upcomingOccurrences(rule: 'FREQ=MONTHLY;INTERVAL=1;BYDAY=4FR', from: day, limit: 3);
    expect(fourth.map((d) => (d.month, d.day)), [(9, 25), (10, 23), (11, 27)]);
    final last = upcomingOccurrences(rule: 'FREQ=MONTHLY;INTERVAL=1;BYDAY=-1FR', from: day, limit: 3);
    expect(last.map((d) => (d.month, d.day)), [(9, 25), (10, 30), (11, 27)]);
  });
}
