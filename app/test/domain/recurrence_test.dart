import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/custom_repeat.dart';
import 'package:task_manager/domain/recurrence.dart';

void main() {
  // Thursday, 2026-09-24.
  final thursday = DateTime(2026, 9, 24);
  final completed = DateTime(2026, 9, 24, 21);

  NextOccurrence? next(String rule, {DateTime? due, RepeatFrom from = RepeatFrom.dueDate, DateTime? at}) =>
      nextOccurrence(rule: rule, dueDate: due ?? thursday, from: from, completedAt: at ?? completed);

  test('daily moves to the next day', () {
    expect(next('FREQ=DAILY;INTERVAL=1')!.dueDate, DateTime(2026, 9, 25));
  });

  test('weekly on Thursday moves one week', () {
    expect(next('FREQ=WEEKLY;INTERVAL=1;BYDAY=TH')!.dueDate, DateTime(2026, 10, 1));
  });

  test('weekdays skip the weekend', () {
    final friday = DateTime(2026, 9, 25);
    expect(next('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', due: friday)!.dueDate, DateTime(2026, 9, 28));
  });

  test('monthly on the 24th and yearly', () {
    expect(next('FREQ=MONTHLY;BYMONTHDAY=24')!.dueDate, DateTime(2026, 10, 24));
    expect(next('FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=24')!.dueDate, DateTime(2027, 9, 24));
  });

  test('monthly on the first Sunday and last day', () {
    expect(next('FREQ=MONTHLY;BYDAY=SU;BYSETPOS=1')!.dueDate, DateTime(2026, 10, 4));
    expect(next('FREQ=MONTHLY;BYMONTHDAY=-1', due: DateTime(2026, 9, 30))!.dueDate, DateTime(2026, 10, 31));
  });

  test('keeps the time of day', () {
    expect(next('FREQ=DAILY', due: DateTime(2026, 9, 24, 18, 48))!.dueDate, DateTime(2026, 9, 25, 18, 48));
  });

  test('by completion date counts from the day it was completed', () {
    final due = DateTime(2026, 9, 20);
    final r = next('FREQ=DAILY;INTERVAL=2', due: due, from: RepeatFrom.completion, at: DateTime(2026, 9, 24, 21));
    expect(r!.dueDate, DateTime(2026, 9, 26));
  });

  test('COUNT is the number of occurrences left and goes down on each completion', () {
    final first = next('FREQ=DAILY;COUNT=3')!;
    expect(first.rule, contains('COUNT=2'));
    final second = nextOccurrence(rule: first.rule, dueDate: first.dueDate, from: RepeatFrom.dueDate, completedAt: completed)!;
    expect(second.rule, contains('COUNT=1'));
    expect(nextOccurrence(rule: second.rule, dueDate: second.dueDate, from: RepeatFrom.dueDate, completedAt: completed), isNull);
  });

  test('UNTIL ends the repetition', () {
    expect(next('FREQ=WEEKLY;UNTIL=20260930T000000Z'), isNull);
    expect(next('FREQ=DAILY;UNTIL=20260930T000000Z')!.dueDate, DateTime(2026, 9, 25));
  });

  test('upcoming occurrences and validation', () {
    expect(upcomingOccurrences(rule: 'FREQ=DAILY', from: thursday, limit: 3), [thursday, DateTime(2026, 9, 25), DateTime(2026, 9, 26)]);
    expect(isValidRule('FREQ=WEEKLY;BYDAY=TH'), isTrue);
    expect(isValidRule('NOT A RULE'), isFalse);
  });

  test('specific dates: next date after the current one, then ends', () {
    final rule = specificDatesRule([DateTime(2026, 10, 3), DateTime(2026, 9, 25), DateTime(2026, 9, 30)]);
    expect(rule, 'DATES=20260925,20260930,20261003');
    expect(isValidRule(rule), isTrue);
    expect(isValidRule('DATES=2026-09-25'), isFalse);
    final n = nextOccurrence(rule: rule, dueDate: DateTime(2026, 9, 25, 14), from: RepeatFrom.dueDate, completedAt: DateTime(2026, 9, 26))!;
    expect(n.dueDate, DateTime(2026, 9, 30, 14));
    expect(nextOccurrence(rule: rule, dueDate: DateTime(2026, 10, 3), from: RepeatFrom.dueDate, completedAt: DateTime(2026, 10, 3)), isNull);
    expect(upcomingOccurrences(rule: rule, from: DateTime(2026, 9, 26)), [DateTime(2026, 9, 30), DateTime(2026, 10, 3)]);
  });

  test('monthly on the last day, on the Nth weekday and on the last workday', () {
    DateTime after(String rule, DateTime due) => nextOccurrence(rule: rule, dueDate: due, from: RepeatFrom.dueDate, completedAt: due)!.dueDate;
    expect(after('FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=-1', DateTime(2026, 9, 30)), DateTime(2026, 10, 31));
    expect(after('FREQ=MONTHLY;INTERVAL=1;BYDAY=1SU', DateTime(2026, 10, 4)), DateTime(2026, 11, 1));
    expect(after('FREQ=MONTHLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1', DateTime(2026, 10, 30)), DateTime(2026, 11, 30));
    expect(after('FREQ=YEARLY;INTERVAL=1;BYMONTH=11;BYDAY=4TH', DateTime(2026, 11, 26)), DateTime(2027, 11, 25));
  });

  test('"Pular finais de semana": a Saturday or Sunday occurrence moves to Monday, and the rule keeps it', () {
    // Daily by completion, completed on Friday 25/09: the next one is Monday.
    final daily = nextOccurrence(
      rule: 'FREQ=DAILY;INTERVAL=1;TT_SKIP=WEEKEND',
      dueDate: DateTime(2026, 9, 24, 9),
      from: RepeatFrom.completion,
      completedAt: DateTime(2026, 9, 25, 18),
    )!;
    expect(daily.dueDate, DateTime(2026, 9, 28, 9));
    expect(skipsWeekends(daily.rule), isTrue);

    // Monthly on the 26th: September's falls on a Saturday.
    const monthly = 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=26;TT_SKIP=WEEKEND';
    expect(
      nextOccurrence(rule: monthly, dueDate: DateTime(2026, 8, 26), from: RepeatFrom.dueDate, completedAt: DateTime(2026, 8, 26))!.dueDate,
      DateTime(2026, 9, 28),
    );
    expect(upcomingOccurrences(rule: monthly, from: DateTime(2026, 9, 1), limit: 3), [
      DateTime(2026, 9, 28),
      DateTime(2026, 10, 26),
      DateTime(2026, 11, 26),
    ]);
    expect(isValidRule(monthly), isTrue);
    expect(withSkipWeekends(monthly, skip: false), 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=26');

    final draft = CustomRepeatDraft.fromRule('FREQ=DAILY;INTERVAL=1;TT_SKIP=WEEKEND', RepeatFrom.completion, DateTime(2026, 9, 25));
    expect((draft.skipWeekends, draft.toRule()), (true, 'FREQ=DAILY;INTERVAL=1;TT_SKIP=WEEKEND'));
  });
}
