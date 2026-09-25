import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/reminders.dart';

void main() {
  test('parses and formats triggers both ways', () {
    const cases = {
      'PT0S': Duration.zero,
      '-PT5M': Duration(minutes: -5),
      '-PT1H': Duration(hours: -1),
      '-P1D': Duration(days: -1),
      'PT9H': Duration(hours: 9),
      '-PT15H': Duration(hours: -15),
      '-P1DT15H': Duration(days: -1, hours: -15),
      '-PT1H30M': Duration(hours: -1, minutes: -30),
    };
    for (final c in cases.entries) {
      expect(parseTrigger(c.key), c.value, reason: c.key);
      expect(formatTrigger(c.value), c.key, reason: c.key);
    }
  });

  test('all-day presets fire at 09:00 on the right day', () {
    final due = DateTime(2026, 9, 26);
    expect(fireTime(due, ReminderPresets.onTheDay), DateTime(2026, 9, 26, 9));
    expect(fireTime(due, ReminderPresets.oneDayBeforeAt9), DateTime(2026, 9, 25, 9));
    expect(fireTime(due, ReminderPresets.twoDaysBeforeAt9), DateTime(2026, 9, 24, 9));
    expect(fireTime(due, ReminderPresets.oneWeekBeforeAt9), DateTime(2026, 9, 19, 9));
  });

  test('invalid triggers are rejected', () {
    for (final bad in ['', 'P', '15M', '-PT', 'PTX']) {
      expect(() => parseTrigger(bad), throwsFormatException, reason: bad);
    }
  });
}
