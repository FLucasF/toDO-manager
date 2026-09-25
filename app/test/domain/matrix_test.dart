import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/matrix.dart';
import 'package:task_manager/domain/views.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  final now = DateTime(2026, 9, 25, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  test('"Tempo + prioridade": importance by priority, urgency by date; a drop fixes both', () async {
    await repo.createTask(listId: inboxListId, title: 'Q1', priority: Priority.high, dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: 'Q2', priority: Priority.medium, dueDate: DateTime(2026, 10, 5));
    await repo.createTask(listId: inboxListId, title: 'Q3', priority: Priority.low, dueDate: DateTime(2026, 9, 20));
    final q4 = await repo.createTask(listId: inboxListId, title: 'Q4');
    final s = await repo.loadSnapshot();
    final rules = QuadrantRule.timeAndPriority;
    expect([for (final r in rules) quadrantTasks(s, r, now: now).map((t) => t.title).join()], ['Q1', 'Q2', 'Q3', 'Q4']);

    final today = DateTime(2026, 9, 25);
    final loose = s.taskById[q4]!;
    expect(quadrantDrop(loose, rules[0], today), (priority: Priority.high, day: today), reason: 'urgent and important');
    final urgent = s.tasks.firstWhere((t) => t.title == 'Q1');
    expect(quadrantDrop(urgent, rules[1], today), (priority: null, day: DateTime(2026, 9, 27)), reason: 'after tomorrow is not urgent');
    expect(quadrantDrop(urgent, rules[0], today), (priority: null, day: null));

    final back = QuadrantRule.fromJson(rules[1].toJson(), QuadrantRule.defaults[1]);
    expect(back.dates, rules[1].dates);
    expect(back.excludeDates, isTrue);
    final withIcon = QuadrantRule.fromJson(const QuadrantRule(name: 'Agora', icon: '🔥').toJson(), QuadrantRule.defaults[0]);
    expect((withIcon.name, withIcon.icon, withIcon.withView(ascending: false).icon), ('Agora', '🔥', '🔥'));
  });

  test('default quadrants follow the priority; groups by date; dragging changes the priority with subtasks', () async {
    final urgent = await repo.createTask(listId: inboxListId, title: 'Urgente', priority: Priority.high, dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: inboxListId, title: 'Hoje', priority: Priority.high, dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: 'Sem data', priority: Priority.high);
    final none = await repo.createTask(listId: inboxListId, title: 'Qualquer');
    await repo.createTask(listId: inboxListId, title: 'Sub', parentId: none);
    var s = await repo.loadSnapshot();

    final q1 = quadrantTasks(s, QuadrantRule.defaults[0]);
    expect(q1.map((t) => t.title), ['Urgente', 'Hoje', 'Sem data']);
    expect(groupQuadrant(s, q1, now).map((g) => g.$1.runtimeType), [OverdueHeader, DayHeader, NoDateHeader]);
    expect(quadrantTasks(s, QuadrantRule.defaults[3]).map((t) => t.title), ['Qualquer'], reason: 'subtasks go with the parent');

    await repo.setPriorityWithSubtasks(none, Priority.medium);
    s = await repo.loadSnapshot();
    expect(s.tasks.where((t) => t.priority == Priority.medium).length, 2);
    expect(urgent, isNotEmpty);
  });

  test('custom rules round-trip through the preferences', () async {
    final prefs = PreferencesRepository(db, clock: FixedClock(now));
    const custom = QuadrantRule(name: 'Trabalho', priorities: {Priority.high, Priority.medium}, kinds: {TaskKind.text});
    await prefs.setMatrixRules([custom, ...QuadrantRule.defaults.skip(1)]);
    final back = (await prefs.watch().first).matrixRules.first;
    expect(back.name, 'Trabalho');
    expect(back.priorities, {Priority.high, Priority.medium});
    expect(back.kinds, {TaskKind.text});
  });

  test('Agrupar por / Ordenar por / Ordem', () async {
    final work = await repo.createList(name: 'Trabalho');
    await repo.createTask(listId: inboxListId, title: 'b', priority: Priority.high);
    await repo.createTask(listId: work, title: 'a', priority: Priority.low, dueDate: DateTime(2026, 9, 26));
    await repo.createTask(listId: work, title: 'c', priority: Priority.high, dueDate: DateTime(2026, 9, 25));
    final s = await repo.loadSnapshot();
    const all = QuadrantRule();
    expect(quadrantTasks(s, all).map((t) => t.title), ['c', 'a', 'b']);
    // Decrescente: later dates first; tasks without a date stay last.
    expect(quadrantTasks(s, all.withView(ascending: false)).map((t) => t.title), ['a', 'c', 'b']);
    expect(quadrantTasks(s, all.withView(sorting: QuadrantSorting.title)).map((t) => t.title), ['a', 'b', 'c']);
    final byPriority = quadrantTasks(s, all.withView(sorting: QuadrantSorting.priority));
    expect(byPriority.first.priority, Priority.high);
    expect(byPriority.last.title, 'a');
    final groups = groupQuadrant(s, quadrantTasks(s, all), now, grouping: QuadrantGrouping.list);
    expect([for (final g in groups) ((g.$1 as ListHeader).listId, g.$2.length)], [(work, 2), (inboxListId, 1)]);
    final rule = QuadrantRule.fromJson(all.withView(grouping: QuadrantGrouping.none, ascending: false).toJson(), all);
    expect((rule.grouping, rule.ascending), (QuadrantGrouping.none, false));
  });
}
