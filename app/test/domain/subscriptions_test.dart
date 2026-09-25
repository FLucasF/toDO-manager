import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/import/ical.dart';
import 'package:task_manager/domain/subscriptions.dart';

const _ics = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Aula de inglês
DTSTART:20260922T220000Z
DTEND:20260922T230000Z
RRULE:FREQ=WEEKLY;COUNT=10
END:VEVENT
BEGIN:VEVENT
SUMMARY:Congresso
DTSTART;VALUE=DATE:20260928
DTEND;VALUE=DATE:20261001
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('Easter and the holidays that follow it', () {
    expect(
      [
        for (final y in [2024, 2025, 2026]) easterSunday(y),
      ],
      [DateTime(2024, 3, 31), DateTime(2025, 4, 20), DateTime(2026, 4, 5)],
    );
    final h2026 = {for (final (day, name) in brazilHolidays(2026)) name: day};
    expect(h2026['Sexta-feira Santa'], DateTime(2026, 4, 3));
    expect(h2026['Corpus Christi'], DateTime(2026, 6, 4));
    expect(brazilHolidays(2026).where((h) => h.$2 == 'Carnaval').map((h) => h.$1), [DateTime(2026, 2, 16), DateTime(2026, 2, 17)]);
    expect(h2026['Dia Nacional de Zumbi e da Consciência Negra'], DateTime(2026, 11, 20));
    expect(brazilHolidays(2023).any((h) => h.$2.startsWith('Dia Nacional de Zumbi')), isFalse);
  });

  test('events in a period: holidays across a new year, and an ICS with a weekly repetition', () {
    const holidays = CalendarSubscription(id: 'h', name: 'Feriados', kind: SubscriptionKind.holidays);
    expect(subscribedEvents(holidays, DateTime(2026, 12, 20), DateTime(2027, 1, 5)).map((e) => (e.title, e.start)), [
      ('Natal', DateTime(2026, 12, 25)),
      ('Confraternização Universal', DateTime(2027)),
    ]);
    expect(subscribedEvents(holidays.copyWith(visible: false), DateTime(2026), DateTime(2027)), isEmpty);

    const url = CalendarSubscription(id: 'u', name: 'Escola', kind: SubscriptionKind.url, url: 'https://example.com/a.ics');
    final events = subscribedEvents(url, DateTime(2026, 9, 27), DateTime(2026, 10, 4), icsEvents: parseICal(_ics));
    expect(
      [for (final e in events) (e.title, e.start, e.isAllDay)],
      [('Congresso', DateTime(2026, 9, 28), true), ('Aula de inglês', DateTime.utc(2026, 9, 29, 22).toLocal(), false)],
    );
    expect(events.first.touches(DateTime(2026, 9, 30)), isTrue);
    expect(events.first.touches(DateTime(2026, 10, 1)), isFalse, reason: 'DTEND of an all-day event is the day after');
    expect(subscribedEvents(url, DateTime(2026), DateTime(2027)), isEmpty, reason: 'not downloaded yet');
  });
}
