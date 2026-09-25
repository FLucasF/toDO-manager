import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/format/date_labels.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  final labels = DateLabels(AppLocalizationsPt());
  // Thursday, 2026-09-24 (the day of the survey).
  final today = DateTime(2026, 9, 24, 21);

  group('day header (texts seen on TickTick)', () {
    test('today, tomorrow and later', () {
      expect(labels.dayHeader(DateTime(2026, 9, 24), today), 'Quinta-feira, Hoje');
      expect(labels.dayHeader(DateTime(2026, 9, 25), today), 'Sexta-feira, Amanhã');
      expect(labels.dayHeader(DateTime(2026, 9, 26), today), 'Sábado, 26 setembro');
    });

    test('yesterday and another year', () {
      expect(labels.dayHeader(DateTime(2026, 9, 23), today), 'Quarta-feira, Ontem');
      expect(labels.dayHeader(DateTime(2027, 1, 1), today), 'Sexta-feira, 1 janeiro 2027');
    });
  });

  group('row date', () {
    test('today with a time shows only the time', () {
      expect(labels.rowDate(DateTime(2026, 9, 24, 18, 48), isAllDay: false, today: today), '18:48');
    });

    test('relative days and weekday', () {
      expect(labels.rowDate(DateTime(2026, 9, 24), isAllDay: true, today: today), 'Hoje');
      expect(labels.rowDate(DateTime(2026, 9, 25), isAllDay: true, today: today), 'Amanhã');
      expect(labels.rowDate(DateTime(2026, 9, 23), isAllDay: true, today: today), 'Ontem');
      expect(labels.rowDate(DateTime(2026, 9, 26), isAllDay: true, today: today), 'Sáb');
    });

    test('farther dates show day and month', () {
      expect(labels.rowDate(DateTime(2026, 10, 15), isAllDay: true, today: today), '15 out');
      expect(labels.rowDate(DateTime(2027, 2, 3), isAllDay: true, today: today), '3 fev 2027');
    });
  });

  test('detail date (texts seen on TickTick)', () {
    expect(labels.detailDate(DateTime(2026, 9, 24, 18, 48), isAllDay: false, today: today), 'Hoje, 24 set, 18:48');
    expect(labels.detailDate(DateTime(2026, 9, 25), isAllDay: true, today: today), 'Amanhã, 25 set');
    expect(labels.detailDate(DateTime(2026, 9, 26), isAllDay: true, today: today), 'Sáb, 26 set');
  });

  test('countdown and ranges', () {
    final labels = DateLabels(AppLocalizationsPt());
    final today = DateTime(2026, 9, 24);
    expect(labels.rowCountdown(DateTime(2026, 9, 27), isAllDay: true, today: today), 'em 3 dias');
    expect(labels.rowCountdown(DateTime(2026, 9, 22), isAllDay: true, today: today), 'há 2 dias');
    expect(labels.rowCountdown(DateTime(2026, 9, 25), isAllDay: true, today: today), 'Amanhã');
    expect(labels.rowCountdown(DateTime(2026, 9, 24, 18, 48), isAllDay: false, today: today), '18:48');
    expect(labels.rowRange(DateTime(2026, 9, 24, 10), DateTime(2026, 9, 24, 11), isAllDay: false, today: today), '10:00-11:00');
    // Another day: the day and both times, not "22 set-12:00".
    expect(labels.rowRange(DateTime(2026, 9, 21, 9), DateTime(2026, 9, 21, 12), isAllDay: false, today: today), '21 set, 09:00-12:00');
    expect(labels.rowRange(DateTime(2026, 9, 25, 9), DateTime(2026, 9, 25, 12), isAllDay: false, today: today), 'Amanhã, 09:00-12:00');
    expect(labels.rowRange(DateTime(2026, 9, 23, 9), DateTime(2026, 9, 23, 12), isAllDay: false, today: today), 'Ontem, 09:00-12:00');
    expect(labels.rowRange(DateTime(2026, 9, 24), DateTime(2026, 9, 26), isAllDay: true, today: today), 'Hoje - Sáb');
    expect(labels.detailRange(DateTime(2026, 9, 24), DateTime(2026, 10, 3), isAllDay: true, today: today), 'Hoje, 24 set - Sáb, 3 out');
  });
}
