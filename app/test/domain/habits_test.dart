import 'package:task_manager/l10n/app_localizations.dart';
import 'package:task_manager/features/habits/habit_export.dart';
import 'package:flutter/widgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/habits.dart';
import 'package:task_manager/domain/reminder_plan.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Friday, 2026-09-25.
  final now = DateTime(2026, 9, 25, 20);
  DateTime day(int d) => DateTime(2026, 9, d);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  Future<(Habit, List<HabitCheckin>)> load(String id) async {
    final s = await repo.loadSnapshot();
    return (s.habits.singleWhere((h) => h.id == id), s.checkinsOf(id));
  }

  test('a daily check-in habit: dots, total and streak; today open does not break the streak', () async {
    final id = await repo.createHabit(HabitsCompanion(name: Value('Ler'), startDate: Value(day(21))));
    for (final d in [21, 22, 23, 24]) {
      await repo.checkIn(id, day(d));
    }
    var (h, c) = await load(id);
    expect(habitDayState(h, null, day(20)), HabitDayState.notRequired, reason: 'before the start date');
    expect(habitDayState(h, c.firstWhere((x) => x.day.day == 24), day(24)), HabitDayState.done);
    var stats = habitStats(h, c, now);
    expect((stats.totalDays, stats.streak), (4, 4));

    await repo.markHabitDay(id, day(23), HabitMark.failed);
    (h, c) = await load(id);
    stats = habitStats(h, c, now);
    expect((stats.totalDays, stats.streak), (3, 1), reason: '"Incompleta" breaks the streak');
  });

  test('amount goals: Automático adds the step, partial days, the goal completes the day', () async {
    final id = await repo.createHabit(
      HabitsCompanion(
        name: Value('Beber água'),
        startDate: Value(day(25)),
        goal: const Value(HabitGoal.amount),
        goalAmount: const Value(8),
        unit: const Value('copos'),
      ),
    );
    await repo.checkIn(id, day(25));
    await repo.checkIn(id, day(25));
    await repo.checkIn(id, day(25));
    var (h, c) = await load(id);
    expect(c.single.value, 3);
    expect(habitDayState(h, c.single, day(25)), HabitDayState.partial);
    await repo.checkIn(id, day(25), amount: 5);
    (h, c) = await load(id);
    expect(habitDayState(h, c.single, day(25)), HabitDayState.done);
    await repo.resetHabitDay(id, day(25));
    (h, c) = await load(id);
    expect(habitDayState(h, c.single, day(25)), HabitDayState.open);
  });

  test('chosen weekdays and every N days decide the due days', () async {
    final weekdays = await repo.createHabit(HabitsCompanion(name: Value('Academia'), startDate: Value(day(21)), weekdays: const Value('1,3,5')));
    final every = await repo.createHabit(
      HabitsCompanion(name: Value('Regar'), startDate: Value(day(21)), frequency: const Value(HabitFrequency.interval), everyDays: const Value(3)),
    );
    final (w, _) = await load(weekdays);
    final (e, _) = await load(every);
    expect([for (var d = 21; d <= 27; d++) habitIsDue(w, day(d))], [true, false, true, false, true, false, false]);
    expect([for (var d = 21; d <= 27; d++) habitIsDue(e, day(d))], [true, false, false, true, false, false, true]);
  });

  test('the log keeps mood and note; deleting the habit deletes its check-ins', () async {
    final id = await repo.createHabit(HabitsCompanion(name: Value('Meditar'), startDate: Value(day(25))));
    await repo.checkIn(id, day(25));
    await repo.saveHabitLog(id, day(25), mood: 4, note: '  Calmo ');
    final (_, c) = await load(id);
    expect((c.single.mood, c.single.note, c.single.value), (4, 'Calmo', 1.0));
    await repo.deleteHabit(id);
    expect(await db.select(db.habitCheckins).get(), isEmpty);
  });

  test('habit reminders: the chosen times on due days, not on days already done', () async {
    final id = await repo.createHabit(
      HabitsCompanion(name: const Value('Alongar'), startDate: Value(day(25)), reminders: const Value('21:00,09:00')),
    );
    await repo.checkIn(id, day(26));
    final plan = planHabitReminders(await repo.loadSnapshot(), now, days: 3);
    expect(plan.map((r) => r.at).toSet(), {DateTime(2026, 9, 25, 21), DateTime(2026, 9, 27, 9), DateTime(2026, 9, 27, 21)});
    expect(plan.every((r) => r.isHabit), isTrue);
  });

  test('export: one row per check-in, with the status and the note', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
    final water = await repo.createHabit(
      HabitsCompanion(
        name: const Value('Beber água'),
        startDate: Value(DateTime.utc(2026, 9, 20)),
        goal: const Value(HabitGoal.amount),
        goalAmount: const Value(8),
        unit: const Value('copos'),
      ),
    );
    await repo.checkIn(water, DateTime(2026, 9, 23), amount: 8);
    await repo.checkIn(water, DateTime(2026, 9, 24), amount: 3);
    final csv = habitsCsv(lookupAppLocalizations(const Locale('pt')), await repo.loadSnapshot()).split(String.fromCharCodes([13, 10]));
    expect(csv, [
      'Hábito;Data;Valor;Meta;Unidade;Status;Humor;Nota',
      'Beber água;23/09/2026;8;8;copos;Concluído;;',
      'Beber água;24/09/2026;3;8;copos;Parcial;;',
    ]);
  });
}
