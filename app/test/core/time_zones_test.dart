import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/time_zones.dart';

void main() {
  final noonUtc = DateTime.utc(2026, 9, 25, 12);
  final winterUtc = DateTime.utc(2026, 1, 15, 12);

  (int, int)? clock(DateTime at, String id) => switch (zoneTime(at, id)) {
    final t? => (t.hour, t.minute),
    null => null,
  };

  test('the clock of another zone at an instant, with daylight saving', () {
    expect(clock(noonUtc, 'America/New_York'), (8, 0));
    expect(clock(winterUtc, 'America/New_York'), (7, 0));
    expect(clock(noonUtc, 'Asia/Kolkata'), (17, 30));
    expect(clock(noonUtc, 'Nowhere/City'), isNull);
  });

  test('a clock reading in a zone ↔ an instant on this device', () {
    final instant = wallToLocal(DateTime(2026, 9, 25, 9), 'America/New_York');
    expect(instant.toUtc(), DateTime.utc(2026, 9, 25, 13));
    expect(localToWall(instant, 'America/New_York'), DateTime(2026, 9, 25, 9));
    expect(wallToLocal(DateTime(2026, 9, 25, 9), 'Nowhere/City'), DateTime(2026, 9, 25, 9));
    expect(deviceZoneId(), isNull, reason: 'known only once the notifications start');
  });

  test('labels: city and offset', () {
    expect(zoneCity('America/Sao_Paulo'), 'Sao Paulo');
    expect(zoneOffsetLabel('America/New_York', noonUtc), 'GMT-4');
    expect(zoneOffsetLabel('Asia/Kolkata', noonUtc), 'GMT+5:30');
    expect(zoneOffsetLabel('Europe/London', winterUtc), 'GMT');
    expect(timeZoneIds(), contains('America/Sao_Paulo'));
    expect(timeZoneIds(), isNot(contains('US/Eastern')), reason: 'aliases are left out');
  });
}
