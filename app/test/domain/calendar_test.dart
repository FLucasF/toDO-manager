import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/calendar.dart';

void main() {
  // Friday, 2026-09-25.
  final now = DateTime(2026, 9, 25, 10);
  const o = CalendarOptions();

  test('periods: month grid from the Sunday before the 1st; week from Sunday; steps', () {
    // September 2026 starts on a Tuesday: the grid starts on Sunday 30/08 and has 5 weeks.
    expect(calendarPeriod(CalendarMode.month, now, o), (from: DateTime(2026, 8, 30), days: 35));
    // August 2026 starts on a Saturday and ends on a Monday: 6 weeks.
    expect(calendarPeriod(CalendarMode.month, DateTime(2026, 8, 10), o).days, 42);
    expect(calendarPeriod(CalendarMode.week, now, o), (from: DateTime(2026, 9, 20), days: 7));
    expect(calendarPeriod(CalendarMode.multiDay, now, o), (from: DateTime(2026, 9, 25), days: 3));
    expect(calendarPeriod(CalendarMode.multiWeek, now, o), (from: DateTime(2026, 9, 20), days: 35));
    expect(calendarPeriod(CalendarMode.year, now, o), (from: DateTime(2026), days: 365));
    expect(calendarStep(CalendarMode.month, DateTime(2026, 1, 31), 1, o), DateTime(2026, 2));
    expect(calendarStep(CalendarMode.week, now, -1, o), DateTime(2026, 9, 18));
    expect(calendarStep(CalendarMode.multiDay, now, 1, o.copyWith(multiDays: 20)), DateTime(2026, 10, 9));
  });

  test('options survive JSON and fall back on bad values', () {
    final back = CalendarOptions.fromJson(
      const CalendarOptions(showCompleted: false, colorBy: CalendarColorBy.priority, multiDays: 7, listIds: {'a'}).toJson(),
    );
    expect((back.showCompleted, back.colorBy, back.multiDays), (false, CalendarColorBy.priority, 7));
    expect(back.listIds, {'a'});
    expect(CalendarOptions.fromJson('x').multiWeeks, 5);
    final look = CalendarOptions.fromJson(
      const CalendarOptions(classicStyle: true, showIcons: true, timeZones: ['Asia/Tokyo', 'Europe/Lisbon']).toJson(),
    );
    expect((look.classicStyle, look.showIcons), (true, true));
    expect(look.timeZones, ['Asia/Tokyo', 'Europe/Lisbon']);
    expect(const CalendarOptions().copyWith(timeZones: ['a', 'b', 'c', 'd', 'e']).timeZones, hasLength(CalendarOptions.maxTimeZones));
    final hours = CalendarOptions.fromJson(const CalendarOptions(hiddenBefore: 6, hiddenAfter: 23).toJson());
    expect((hours.hiddenBefore, hours.hiddenAfter), (6, 23));
    expect(const CalendarOptions().copyWith(hiddenBefore: 20, hiddenAfter: 30).hiddenBefore, 12, reason: 'kept within the morning');
  });

  group('entries', () {
    late AppDatabase db;
    late Repository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db, clock: FixedClock(now));
    });
    tearDown(() => db.close());

    test('tasks in range, completed ones by option, archived lists left out', () async {
      await repo.createTask(listId: inboxListId, title: 'hoje', dueDate: DateTime(2026, 9, 25));
      await repo.createTask(listId: inboxListId, title: 'reunião', dueDate: DateTime(2026, 9, 25, 14), isAllDay: false);
      await repo.createTask(listId: inboxListId, title: 'viagem', startDate: DateTime(2026, 9, 18), dueDate: DateTime(2026, 9, 21));
      await repo.createTask(listId: inboxListId, title: 'longe', dueDate: DateTime(2026, 11, 2));
      await repo.createTask(listId: inboxListId, title: 'sem data');
      final done = await repo.createTask(listId: inboxListId, title: 'feita', dueDate: DateTime(2026, 9, 24));
      await repo.complete(done);
      final archived = await repo.createList(name: 'Velha');
      await repo.createTask(listId: archived, title: 'arquivada', dueDate: DateTime(2026, 9, 25));
      await repo.archiveList(archived, archived: true);

      final s = await repo.loadSnapshot();
      List<String> titles(CalendarOptions o) => [
        for (final e in calendarEntries(s, DateTime(2026, 9, 20), DateTime(2026, 9, 27), o, now: now)) e.title,
      ];
      // The trip started before the week and still shows; sorted by start.
      expect(titles(o), ['viagem', 'feita', 'hoje', 'reunião']);
      expect(titles(o.copyWith(showCompleted: false)), ['viagem', 'hoje', 'reunião']);
      final meeting = calendarEntries(s, DateTime(2026, 9, 25), DateTime(2026, 9, 26), o, now: now).last;
      // A time without a duration gets a 30-minute block.
      expect((meeting.isAllDay, meeting.end), (false, DateTime(2026, 9, 25, 14, 30)));
    });

    test('"Mostrar ciclos futuros" adds the next occurrences; habits with a reminder time show', () async {
      final weekly = await repo.createTask(listId: inboxListId, title: 'academia', dueDate: DateTime(2026, 9, 21, 7), isAllDay: false);
      await repo.setRepeat(weekly, 'FREQ=DAILY;INTERVAL=2');
      await repo.createHabit(HabitsCompanion(name: const Value('Ler'), startDate: Value(DateTime.utc(2026, 9, 1)), reminders: const Value('21:00')));
      final s = await repo.loadSnapshot();
      final entries = calendarEntries(s, DateTime(2026, 9, 20), DateTime(2026, 9, 27), o, now: now);
      final gym = entries.where((e) => e.title == 'academia').toList();
      expect([for (final e in gym) (e.start.day, e.isOccurrence)], [(21, false), (23, true), (25, true)]);
      expect(entries.where((e) => e.kind == CalendarEntryKind.habit).map((e) => e.start), [for (var d = 20; d < 27; d++) DateTime(2026, 9, d, 21)]);
      expect(calendarEntries(s, DateTime(2026, 9, 20), DateTime(2026, 9, 27), o.copyWith(showRepeats: false, showHabits: false), now: now).length, 1);
    });
  });

  CalendarEntry timed(String title, int h1, int m1, int h2, int m2) => CalendarEntry(
    kind: CalendarEntryKind.task,
    id: title,
    title: title,
    start: DateTime(2026, 9, 25, h1, m1),
    end: DateTime(2026, 9, 25, h2, m2),
    isAllDay: false,
  );

  test('timeline: overlapping entries sit side by side, separate groups keep full width', () {
    final slots = layoutTimeline([timed('a', 9, 0, 10, 0), timed('b', 9, 30, 11, 0), timed('c', 10, 0, 10, 30), timed('d', 12, 0, 13, 0)]);
    expect([for (final s in slots) (s.entry.title, s.column, s.columns)], [('a', 0, 2), ('b', 1, 2), ('c', 0, 2), ('d', 0, 1)]);
  });

  CalendarEntry allDay(String title, int from, int to) => CalendarEntry(
    kind: CalendarEntryKind.task,
    id: title,
    title: title,
    start: DateTime(2026, 9, from),
    end: DateTime(2026, 9, to),
    isAllDay: true,
  );

  test('spans: longer bars first, each on the first free lane; bars cut at the row edges', () {
    final row = DateTime(2026, 9, 20);
    final slots = layoutSpans([allDay('um dia', 22, 22), allDay('semana', 18, 23), allDay('outro', 23, 29), allDay('fora', 1, 2)], row, 7);
    expect([for (final s in slots) (s.entry.title, s.first, s.last, s.lane)], [('semana', 0, 3, 0), ('um dia', 2, 2, 1), ('outro', 3, 6, 1)]);
    expect((slots[0].continuesBefore(row), slots[2].continuesAfter(row, 7)), (true, true));
  });

  test('moving: all-day keeps its days, timed keeps its time and length, the timeline sets a time', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(now));
    final trip = await repo.createTask(listId: inboxListId, title: 'viagem', startDate: DateTime(2026, 9, 18), dueDate: DateTime(2026, 9, 21));
    final call = await repo.createTask(
      listId: inboxListId,
      title: 'ligação',
      startDate: DateTime(2026, 9, 25, 14),
      dueDate: DateTime(2026, 9, 25, 15, 30),
      isAllDay: false,
    );
    final s = await repo.loadSnapshot();
    expect(movedDates(s.taskById[trip]!, DateTime(2026, 10, 1)), (start: DateTime(2026, 10, 1), due: DateTime(2026, 10, 4), isAllDay: true));
    expect(movedDates(s.taskById[call]!, DateTime(2026, 9, 28)), (
      start: DateTime(2026, 9, 28, 14),
      due: DateTime(2026, 9, 28, 15, 30),
      isAllDay: false,
    ));
    expect(movedDates(s.taskById[call]!, DateTime(2026, 9, 28), time: DateTime(2026, 9, 28, 8)), (
      start: DateTime(2026, 9, 28, 8),
      due: DateTime(2026, 9, 28, 9, 30),
      isAllDay: false,
    ));
    expect(movedDates(s.taskById[trip]!, DateTime(2026, 9, 28), time: DateTime(2026, 9, 28, 8)), (
      start: DateTime(2026, 9, 28, 8),
      due: DateTime(2026, 9, 28, 8),
      isAllDay: false,
    ));
    expect(snapTime(DateTime(2026, 9, 25, 9, 44)), DateTime(2026, 9, 25, 9, 30));
  });

  test('timeline: bars move by days; edges change start or end, never crossing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(now));
    final id = await repo.createTask(listId: inboxListId, title: 'sprint', startDate: DateTime(2026, 9, 21), dueDate: DateTime(2026, 9, 25));
    final t = (await repo.loadSnapshot()).taskById[id]!;
    expect(shiftedDates(t, startDays: 2, endDays: 2), (start: DateTime(2026, 9, 23), due: DateTime(2026, 9, 27), isAllDay: true));
    expect(shiftedDates(t, endDays: -2).due, DateTime(2026, 9, 23));
    expect(shiftedDates(t, startDays: 10).start, DateTime(2026, 9, 25));
    expect(shiftedDates(t, endDays: -10).due, DateTime(2026, 9, 21));
  });
}
