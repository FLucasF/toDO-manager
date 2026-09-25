import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';

/// A clock the test moves forward.
class _Clock implements Clock {
  DateTime value = DateTime(2026, 9, 25, 10);

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

  Future<List<(ActivityAction, String)>> taskLog(String id) async => [
    for (final a in (await repo.watchTaskActivities(id).first).reversed) (a.action, a.detail),
  ];

  test('task changes are recorded; edits of the same field minutes apart merge', () async {
    final work = await repo.createList(name: 'Trabalho');
    final id = await repo.createTask(listId: inboxListId, title: 'rascunho');
    clock.value = clock.value.add(const Duration(minutes: 1));
    await repo.setTitle(id, 'Relatório');
    clock.value = clock.value.add(const Duration(minutes: 2));
    await repo.setTitle(id, 'Relatório mensal');
    await repo.setPriority(id, Priority.high);
    await repo.move(id, work);
    await repo.setDueDate(id, DateTime(2026, 9, 30));
    // The same field again much later is a new entry.
    clock.value = clock.value.add(const Duration(hours: 1));
    await repo.setTitle(id, 'Relatório de setembro');
    await repo.complete(id);
    await repo.reopen(id);

    final log = await taskLog(id);
    expect(
      [for (final e in log) e.$1],
      [
        ActivityAction.created,
        ActivityAction.title,
        ActivityAction.priority,
        ActivityAction.moved,
        ActivityAction.date,
        ActivityAction.title,
        ActivityAction.completed,
        ActivityAction.reopened,
      ],
    );
    expect(log[1].$2, 'Relatório mensal');
    expect((log[2].$2, log[3].$2), ('5', work));
    // The list's activities: its creation and every entry of its task after the move.
    final listLog = await repo.watchListActivities(work).first;
    expect(listLog.last.action, ActivityAction.listCreated);
    expect(listLog.where((a) => a.taskId == id).length, 5);
  });

  test('a repeating task records one completion, not a date change; ordering does not log', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'academia', dueDate: DateTime(2026, 9, 25));
    await repo.setRepeat(id, 'FREQ=DAILY');
    await repo.complete(id);
    final other = await repo.createTask(listId: inboxListId, title: 'b');
    await repo.moveBefore(other, id);
    expect([for (final e in await taskLog(id)) e.$1], [ActivityAction.created, ActivityAction.repeat, ActivityAction.completed]);
    expect([for (final e in await taskLog(other)) e.$1], [ActivityAction.created]);
  });

  test('pin, parent and tags are recorded too', () async {
    final parent = await repo.createTask(listId: inboxListId, title: 'pai');
    final id = await repo.createTask(listId: inboxListId, title: 'filho');
    final tag = await repo.createTag('casa');
    await repo.pinTask(id, pinned: true);
    await repo.makeSubtask(id, parent);
    await repo.setTaskTags(id, {tag});
    final log = await taskLog(id);
    expect([for (final e in log) e.$1], [ActivityAction.created, ActivityAction.pinned, ActivityAction.parent, ActivityAction.tags]);
    expect((log[2].$2, log[3].$2), (parent, '#casa'));
  });
}
