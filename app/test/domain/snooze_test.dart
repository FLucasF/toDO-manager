import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/snooze.dart';

void main() {
  test('snooze times', () {
    final now = DateTime(2026, 9, 25, 18, 48);
    expect(snoozeTime(SnoozeOption.minutes15, now), DateTime(2026, 9, 25, 19, 3));
    expect(snoozeTime(SnoozeOption.hours3, now), DateTime(2026, 9, 25, 21, 48));
    expect(snoozeTime(SnoozeOption.tonight, now), DateTime(2026, 9, 25, 20));
    expect(snoozeTime(SnoozeOption.tonight, DateTime(2026, 9, 25, 21)), isNull);
    expect(snoozeTime(SnoozeOption.tomorrow, DateTime(2026, 9, 30, 23)), DateTime(2026, 10, 1, 9));
  });
}
