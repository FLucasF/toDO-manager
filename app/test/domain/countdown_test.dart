import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/countdown.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/reminder_plan.dart';
import 'package:task_manager/features/countdown/countdown_card.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Friday, 2026-09-25.
  final now = DateTime(2026, 9, 25, 15);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  Future<Countdown> make({
    required DateTime date,
    CountdownType type = CountdownType.countdown,
    CountMode mode = CountMode.standard,
    String? rule,
    bool showAge = false,
    CountdownVisibility visibility = CountdownVisibility.onTheDay,
  }) async {
    final id = await repo.createCountdown(
      name: 'x',
      date: date,
      type: type,
      countMode: mode,
      repeatRule: rule,
      showAge: showAge,
      visibility: visibility,
    );
    return (await repo.loadSnapshot()).countdowns.singleWhere((c) => c.id == id);
  }

  test('days until, today and since, in both counting modes', () async {
    final future = countdownStatus(await make(date: DateTime(2026, 9, 27)), now);
    expect((future.phase, future.days, future.target), (CountdownPhase.future, 2, DateTime(2026, 9, 27)));

    expect(countdownStatus(await make(date: DateTime(2026, 9, 25)), now).days, 0);
    expect(countdownStatus(await make(date: DateTime(2026, 9, 25), mode: CountMode.plusOne), now).days, 1);

    final past = countdownStatus(await make(date: DateTime(2026, 9, 20)), now);
    expect((past.phase, past.days), (CountdownPhase.past, 5));
    expect(countdownStatus(await make(date: DateTime(2026, 9, 20), mode: CountMode.plusOne), now).days, 6);
  });

  test('repeating countdowns count to the next occurrence; birthdays show the age', () async {
    final birthday = await make(date: DateTime(1990, 5, 10), type: CountdownType.birthday, rule: 'FREQ=YEARLY;INTERVAL=1', showAge: true);
    final b = countdownStatus(birthday, now);
    expect((b.target, b.age, b.phase), (DateTime(2027, 5, 10), 37, CountdownPhase.future));

    final weekend = await make(date: DateTime(2026, 9, 19), rule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=SA');
    expect(countdownStatus(weekend, now).target, DateTime(2026, 9, 26));
    expect(countdownStatus(weekend, DateTime(2026, 9, 26, 8)).phase, CountdownPhase.today);
  });

  test('"Mostrar na Lista Inteligente" decides the days it shows', () async {
    final soon = await make(date: DateTime(2026, 9, 27), visibility: CountdownVisibility.threeDaysBefore);
    expect(countdownShowsOn(soon, now, now), isTrue);
    final onDay = await make(date: DateTime(2026, 9, 27));
    expect(countdownShowsOn(onDay, now, now), isFalse);
    expect(countdownShowsOn(onDay, DateTime(2026, 9, 27), now), isTrue);
    await repo.archiveCountdown(soon.id, archived: true);
    final archived = (await repo.loadSnapshot()).countdowns.singleWhere((c) => c.id == soon.id);
    expect(countdownShowsOn(archived, now, now), isFalse);
  });

  test('countdown reminders fire from the day at midnight, also for the next occurrence', () async {
    await repo.createCountdown(name: 'Viagem', date: DateTime(2026, 9, 28), reminders: {'PT9H', '-P2DT15H'});
    await repo.createCountdown(name: 'Sábado', date: DateTime(2026, 9, 26), repeatRule: 'FREQ=WEEKLY;INTERVAL=1;BYDAY=SA', reminders: {'PT9H'});
    final plan = planCountdownReminders(await repo.loadSnapshot(), now, (c, at) => c.name);
    expect(
      plan.map((r) => (r.title, r.at)).toSet(),
      {
        ('Viagem', DateTime(2026, 9, 28, 9)),
        ('Viagem', DateTime(2026, 9, 25, 9)),
        ('Sábado', DateTime(2026, 9, 26, 9)),
        ('Sábado', DateTime(2026, 10, 3, 9)),
      }.where((e) => e.$2.isAfter(now)).toSet(),
    );
    expect(plan.every((r) => r.isCountdown), isTrue);
  });

  test('the number in weeks, months and years', () {
    final from = DateTime(2026, 9, 24);
    expect(countdownIn(CountdownUnit.weeks, 99, from, DateTime(2027)), 14);
    expect(countdownIn(CountdownUnit.months, 99, from, DateTime(2027)), 3);
    expect(countdownIn(CountdownUnit.months, 30, from, DateTime(2026, 10, 24)), 1);
    expect(countdownIn(CountdownUnit.months, 29, from, DateTime(2026, 10, 23)), 0);
    expect(countdownIn(CountdownUnit.years, 800, DateTime(2024, 9, 24), from), 2);
  });

  test('"Modo de Contagem: Cronômetro" counts up from the date; the click flips it', () async {
    final id = await repo.createCountdown(
      name: 'Nascimento',
      date: DateTime(1990, 9, 30),
      type: CountdownType.birthday,
      repeatRule: 'FREQ=YEARLY;INTERVAL=1',
      showAge: true,
      countUp: true,
    );
    final c = (await repo.loadSnapshot()).countdowns.singleWhere((x) => x.id == id);
    final up = countdownStatus(c, now);
    expect((up.phase, up.target, up.days, up.age), (CountdownPhase.past, DateTime(1990, 9, 30), 13144, 35));
    final down = countdownStatus(c, now, countUp: false);
    expect((down.phase, down.target, down.days, down.age), (CountdownPhase.future, DateTime(2026, 9, 30), 5, 36));
    // A date still ahead has nothing to count up from.
    final ahead = await make(date: DateTime(2026, 10, 1));
    expect(countdownStatus(ahead, now, countUp: true).phase, CountdownPhase.future);
  });

  test('cards by the nearest date, past ones after; only one pinned', () async {
    final later = await make(date: DateTime(2026, 12, 25));
    final soon = await make(date: DateTime(2026, 9, 27));
    final past = await make(date: DateTime(2026, 9, 1));
    expect(sortCountdowns([later, past, soon], now).map((c) => c.date.month), [9, 12, 9]);
    expect(sortCountdowns([later, past, soon], now).first.id, soon.id);
    expect(sortCountdowns([later, past, soon], now).last.id, past.id);

    await repo.pinCountdown(later.id, pinned: true);
    await repo.pinCountdown(past.id, pinned: true);
    final s = await repo.loadSnapshot();
    expect(
      [
        for (final c in s.countdowns)
          if (c.pinnedAt != null) c.id,
      ],
      [past.id],
    );
    expect(sortCountdowns(s.countdowns, now).first.id, past.id);
  });
}
