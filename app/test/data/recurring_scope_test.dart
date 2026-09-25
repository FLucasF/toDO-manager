import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/recurrence.dart';

void main() {
  group('rule exceptions', () {
    // Every Thursday from 24 September 2026, at 09:00.
    const weekly = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH';
    final start = DateTime(2026, 9, 24, 9);

    test('an excluded day leaves the occurrences and is skipped by the next one', () {
      final rule = excludingDay(weekly, DateTime(2026, 10, 1));
      expect(rule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH;TT_EXDATE=20261001');
      expect(occurrencesBetween(rule: rule, start: start, from: start, to: DateTime(2026, 10, 16)), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 10, 8, 9),
        DateTime(2026, 10, 15, 9),
      ]);
      final next = nextOccurrence(rule: rule, dueDate: start, from: RepeatFrom.dueDate, completedAt: start)!;
      expect(next.dueDate, DateTime(2026, 10, 8, 9));
      expect(next.rule, contains('TT_EXDATE=20261001'), reason: 'the exceptions stay with the series');
      expect(isValidRule(rule), isTrue);
    });

    test('ending on a day replaces COUNT or UNTIL; specific dates drop the ones after', () {
      expect(endingOn('$weekly;COUNT=5', DateTime(2026, 10, 7)), '$weekly;UNTIL=20261007T235959Z');
      expect(occurrencesBetween(rule: endingOn(weekly, DateTime(2026, 10, 7)), start: start, from: start, to: DateTime(2026, 12, 1)), [
        DateTime(2026, 9, 24, 9),
        DateTime(2026, 10, 1, 9),
      ]);
      expect(endingOn('DATES=20260925,20261003', DateTime(2026, 9, 30)), 'DATES=20260925');
      expect(excludingDay('DATES=20260925,20261003', DateTime(2026, 9, 25)), 'DATES=20261003');
    });
  });

  group('repository: Somente esta / Esta e as seguintes', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 24, 8)));
    });
    tearDown(() => db.close());

    Future<String> weeklyMeeting() => repo.createTask(
      listId: inboxListId,
      title: 'Reunião',
      startDate: DateTime(2026, 9, 24, 9),
      dueDate: DateTime(2026, 9, 24, 10),
      isAllDay: false,
      repeatRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH',
    );

    test('skipping the current occurrence moves the task to the next one, keeping its length', () async {
      final id = await weeklyMeeting();
      await repo.skipOccurrence(id, DateTime(2026, 9, 24, 9));
      final t = await repo.task(id);
      expect((t.startDate!.toLocal(), t.dueDate!.toLocal()), (DateTime(2026, 10, 1, 9), DateTime(2026, 10, 1, 10)));
      expect(t.deletedAt, isNull);
    });

    test('skipping a later occurrence excludes it; ending before a later one sets UNTIL; before the first deletes', () async {
      final id = await weeklyMeeting();
      await repo.skipOccurrence(id, DateTime(2026, 10, 8, 9));
      expect((await repo.task(id)).repeatRule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH;TT_EXDATE=20261008');
      await repo.endSeriesBefore(id, DateTime(2026, 10, 15, 9));
      expect((await repo.task(id)).repeatRule, 'FREQ=WEEKLY;INTERVAL=1;BYDAY=TH;TT_EXDATE=20261008;UNTIL=20261014T235959Z');

      final before = await repo.task(id);
      await repo.endSeriesBefore(id, DateTime(2026, 9, 24, 9));
      expect((await repo.task(id)).deletedAt, isNotNull);
      await repo.restoreSeries(before);
      final back = await repo.task(id);
      expect((back.deletedAt, back.repeatRule), (null, before.repeatRule));
    });
  });
}
