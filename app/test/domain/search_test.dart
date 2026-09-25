import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/search.dart';

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
  });
  tearDown(() => db.close());

  test('matches title, content and checklist ignoring case and accents; titles first', () async {
    await repo.createTask(listId: inboxListId, title: 'Ligar para o médico');
    await repo.createTask(listId: inboxListId, title: 'Consulta', content: 'Levar exames ao **MEDICO** às 15h');
    final pack = await repo.createTask(listId: inboxListId, title: 'Viagem', kind: TaskKind.checklist);
    await repo.addChecklistItem(pack, title: 'Receita do médico');
    await repo.createTask(listId: inboxListId, title: 'Comprar pão');

    final hits = searchTasks(await repo.loadSnapshot(), 'medico');
    expect(hits.map((h) => (h.task.title, h.field)), [
      ('Ligar para o médico', SearchField.title),
      ('Consulta', SearchField.content),
      ('Viagem', SearchField.checklist),
    ]);
    final content = hits[1];
    expect(content.snippet, 'Levar exames ao MEDICO às 15h', reason: 'markdown removed');
    expect(content.snippet.substring(content.matchStart, content.matchStart + content.matchLength), 'MEDICO');
  });

  test('empty query lists everything; filters narrow it; deleted tasks never show', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'A', priority: Priority.high, dueDate: DateTime(2026, 9, 26));
    final work = await repo.createList(name: 'Trabalho');
    await repo.createTask(listId: work, title: 'B');
    final c = await repo.createTask(listId: inboxListId, title: 'C');
    await repo.complete(c);
    final d = await repo.createTask(listId: inboxListId, title: 'D');
    await repo.delete(d);
    final s = await repo.loadSnapshot();

    expect(searchTasks(s, '').map((h) => h.task.title).toSet(), {'A', 'B', 'C'});
    expect(searchTasks(s, '', filters: SearchFilters(listIds: {work})).map((h) => h.task.title), ['B']);
    expect(searchTasks(s, '', filters: const SearchFilters(priorities: {Priority.high})).map((h) => h.task.id), [a]);
    expect(searchTasks(s, '', filters: const SearchFilters(statuses: {TaskStatus.completed})).map((h) => h.task.id), [c]);
    expect(
      searchTasks(
        s,
        '',
        filters: SearchFilters(from: DateTime(2026, 9, 26), to: DateTime(2026, 9, 30)),
      ).map((h) => h.task.id),
      [a],
    );
  });

  test('date presets: Sunday weeks and calendar months', () {
    final today = DateTime(2026, 9, 25); // Friday
    expect(searchDateRange(SearchDatePreset.thisWeek, today), (from: DateTime(2026, 9, 20), to: DateTime(2026, 9, 26)));
    expect(searchDateRange(SearchDatePreset.nextWeek, today), (from: DateTime(2026, 9, 27), to: DateTime(2026, 10, 3)));
    expect(searchDateRange(SearchDatePreset.lastWeek, today), (from: DateTime(2026, 9, 13), to: DateTime(2026, 9, 19)));
    expect(searchDateRange(SearchDatePreset.thisMonth, today), (from: DateTime(2026, 9), to: DateTime(2026, 9, 30)));
    expect(searchDateRange(SearchDatePreset.lastMonth, DateTime(2026, 1, 10)), (from: DateTime(2025, 12), to: DateTime(2025, 12, 31)));
    expect(searchDateRange(SearchDatePreset.all, today), isNull);
  });

  test('archived lists are left out, unless searching in them', () async {
    final old = await repo.createList(name: 'Antiga');
    await repo.createTask(listId: old, title: 'relatório arquivado');
    await repo.createTask(listId: inboxListId, title: 'relatório ativo');
    await repo.archiveList(old, archived: true);
    final s = await repo.loadSnapshot();
    expect(searchTasks(s, 'relatorio').map((h) => h.task.title), ['relatório ativo']);
    expect(searchTasks(s, 'relatorio', filters: const SearchFilters(archived: true)).map((h) => h.task.title), ['relatório arquivado']);
  });
}
