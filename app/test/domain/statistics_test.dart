import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/domain/statistics.dart';

class _Clock implements Clock {
  DateTime value = DateTime(2026, 9, 21, 9);

  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late Repository repo;
  late _Clock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = _Clock();
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  test('periods: days, Sunday weeks and months, oldest first', () {
    final day = DateTime(2026, 9, 25);
    expect(periodStart(StatsPeriod.week, day), DateTime(2026, 9, 20));
    expect(periodEnd(StatsPeriod.month, DateTime(2026, 12)), DateTime(2027));
    expect(recentPeriods(StatsPeriod.day, day, count: 3), [DateTime(2026, 9, 23), DateTime(2026, 9, 24), DateTime(2026, 9, 25)]);
    expect(recentPeriods(StatsPeriod.month, day, count: 2), [DateTime(2026, 8), DateTime(2026, 9)]);
  });

  test('completion, rate, distribution and grouping; the score counts up to today 00:00', () async {
    // Monday 21: three tasks due on the 22nd, one on the 23rd.
    final work = await repo.createList(name: 'Trabalho');
    final a = await repo.createTask(listId: work, title: 'a', dueDate: DateTime(2026, 9, 22), priority: Priority.high);
    final b = await repo.createTask(listId: inboxListId, title: 'b', dueDate: DateTime(2026, 9, 22));
    await repo.createTask(listId: inboxListId, title: 'c', dueDate: DateTime(2026, 9, 22));
    final d = await repo.createTask(listId: work, title: 'd', dueDate: DateTime(2026, 9, 23));
    clock.value = DateTime(2026, 9, 22, 18);
    await repo.complete(a);
    clock.value = DateTime(2026, 9, 24, 10);
    await repo.complete(b);
    await repo.complete(d);

    final s = await repo.loadSnapshot();
    final day22 = DateTime(2026, 9, 22), day23 = DateTime(2026, 9, 23);
    expect(completedBetween(s, day22, day23).map((t) => t.title), ['a']);
    expect(completionRate(s, day22, day23), closeTo(2 / 3, 1e-9));
    expect(completionDistribution(s, day22, day23), (onTime: 1, late: 1, undone: 1));
    final week = DateTime(2026, 9, 20);
    expect(completedBy(s, week, periodEnd(StatsPeriod.week, week), StatsGrouping.list), [(work, 2), (inboxListId, 1)]);
    expect(completedBy(s, week, periodEnd(StatsPeriod.week, week), StatsGrouping.priority).first, ('0', 2));

    // On the 24th: 4 created before today (+4), a done on time on the 22nd (+3), c overdue (−1);
    // b and d were completed today and only count tomorrow.
    expect(achievementScore(s, DateTime(2026, 9, 24, 12)), 6);
    expect(achievementScore(s, DateTime(2026, 9, 25)), 6 + 2 + 2);
    expect(achievementLevel(6), (level: 1, next: 50));
    expect(achievementLevel(6000).level, 12);
    expect(daysOfUse(s, DateTime(2026, 9, 24, 12)), 4);
  });

  test('focus: pomos, duration, by list, by hour and the annual grid levels', () async {
    final work = await repo.createList(name: 'Trabalho');
    final task = await repo.createTask(listId: work, title: 'relatório');
    await repo.addFocusRecord(
      FocusRecordDraft(
        startedAt: DateTime(2026, 9, 24, 9, 30),
        endedAt: DateTime(2026, 9, 24, 10, 20),
        seconds: 50 * 60,
        mode: FocusMode.pomo,
        taskId: task,
      ),
    );
    await repo.addFocusRecord(
      FocusRecordDraft(startedAt: DateTime(2026, 9, 24, 14), endedAt: DateTime(2026, 9, 24, 14, 10), seconds: 600, mode: FocusMode.stopwatch),
    );
    final records = await repo.watchFocusRecords().first;
    final s = await repo.loadSnapshot();
    final day = DateTime(2026, 9, 24), next = DateTime(2026, 9, 25);
    expect(pomosBetween(records, day, next), 1);
    expect(focusBetween(records, day, next), const Duration(minutes: 60));
    expect(focusBy(s, records, day, next, StatsGrouping.list), [(work, const Duration(minutes: 50)), ('', const Duration(minutes: 10))]);
    final grid = focusByHour(records, day, 1);
    expect((grid[0][9], grid[0][10], grid[0][14]), (30.0, 20.0, 10.0));
    expect(
      [
        for (final m in [0, 30, 90, 200, 400]) focusDayLevel(Duration(minutes: m)),
      ],
      [0, 1, 2, 3, 4],
    );
  });

  test('medals: days of use, tasks (50 a day at most), focus minutes, habit days', () async {
    for (var i = 0; i < 55; i++) {
      await repo.complete(await repo.createTask(listId: inboxListId, title: 't$i'));
    }
    await repo.addFocusRecord(
      FocusRecordDraft(startedAt: DateTime(2026, 9, 21, 10), endedAt: DateTime(2026, 9, 21, 11), seconds: 3600, mode: FocusMode.pomo),
    );
    final records = await repo.watchFocusRecords().first;
    final m = {for (final medal in medals(await repo.loadSnapshot(), records, DateTime(2026, 9, 23))) medal.kind: medal};
    expect((m[MedalKind.getThingsDone]!.value, m[MedalKind.getThingsDone]!.level, m[MedalKind.getThingsDone]!.next), (50, 3, 100));
    expect((m[MedalKind.mindfulness]!.value, m[MedalKind.mindfulness]!.level), (60, 1));
    expect((m[MedalKind.perseverance]!.value, m[MedalKind.perseverance]!.level), (3, 1));
    expect(m[MedalKind.selfDiscipline]!.level, 0);
  });
}
