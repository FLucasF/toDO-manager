import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/views.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Thursday, 2026-09-24, noon.
  final now = DateTime(2026, 9, 24, 12);
  final clock = FixedClock(now);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  List<String> titles(ViewContent v) => [
    for (final g in v.groups)
      for (final r in g.rows) r.task.title,
  ];
  List<Type> headers(ViewContent v) => [for (final g in v.groups) g.header.runtimeType];

  test('list with pinned and unpinned tasks: Fixado, Não fixado, Concluído', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'a');
    await repo.createTask(listId: inboxListId, title: 'b');
    final c = await repo.createTask(listId: inboxListId, title: 'c');
    await repo.pinTask(a, pinned: true);
    await repo.complete(c);
    final v = buildView(await repo.loadSnapshot(), const ListScope(inboxListId), now);
    expect(headers(v), [PinnedHeader, UnpinnedHeader, ClosedHeader]);
    expect(titles(v), ['a', 'b', 'c']);
    expect(v.groups.last.isClosed, isTrue);
  });

  test('"Agrupar por Lista" outside a list, and "Ordem: Decrescente" keeps pinned first', () async {
    final work = await repo.createList(name: 'Trabalho');
    await repo.createTask(listId: inboxListId, title: 'caixa', dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: work, title: 'trabalho', dueDate: DateTime(2026, 9, 24));
    final pinned = await repo.createTask(listId: work, title: 'fixada', dueDate: DateTime(2026, 9, 24));
    await repo.pinTask(pinned, pinned: true);
    final s = await repo.loadSnapshot();
    const byList = ViewOptions(grouping: Grouping.list, sorting: Sorting.title);
    final v = buildView(s, const SmartScope(SmartList.today), now, options: byList);
    expect([for (final g in v.groups) g.key], ['pinned', 'list:$inboxListId', 'list:$work']);
    final down = buildView(s, const SmartScope(SmartList.today), now, options: byList.copyWith(descending: true));
    expect([for (final g in down.groups) g.key], ['pinned', 'list:$work', 'list:$inboxListId']);
  });

  test('"Tarefas Sugeridas": overdue, the next days, undated by priority; "+" brings a task to today', () async {
    await repo.createTask(listId: inboxListId, title: 'atrasada', dueDate: DateTime(2026, 9, 20, 10), isAllDay: false);
    await repo.createTask(listId: inboxListId, title: 'hoje', dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: inboxListId, title: 'sábado', dueDate: DateTime(2026, 9, 26));
    await repo.createTask(listId: inboxListId, title: 'longe', dueDate: DateTime(2026, 10, 30));
    await repo.createTask(listId: inboxListId, title: 'sem data');
    await repo.createTask(listId: inboxListId, title: 'importante', priority: Priority.high);
    final s = await repo.loadSnapshot();
    final got = suggestedForToday(s, now);
    List<String> names(List<Task> tasks) => [for (final t in tasks) t.title];
    expect(names(got.overdue), ['atrasada']);
    expect(names(got.upcoming), ['sábado']);
    expect(names(got.noDate), ['importante', 'sem data']);

    final late = s.tasks.firstWhere((t) => t.title == 'atrasada');
    await repo.moveToDay(late.id, DateTime(2026, 9, 24));
    expect((await repo.task(late.id)).dueDate!.toLocal(), DateTime(2026, 9, 24, 10), reason: 'keeps its time');
  });

  test('without pinned tasks the open group has no header', () async {
    await repo.createTask(listId: inboxListId, title: 'a');
    final v = buildView(await repo.loadSnapshot(), const ListScope(inboxListId), now);
    expect(headers(v), [NoHeader]);
  });

  test('subtasks are nested under the parent with depth; collapsing hides them', () async {
    final p = await repo.createTask(listId: inboxListId, title: 'pai');
    final c = await repo.createTask(listId: inboxListId, title: 'filho', parentId: p);
    await repo.createTask(listId: inboxListId, title: 'neto', parentId: c);
    final s = await repo.loadSnapshot();
    final v = buildView(s, const ListScope(inboxListId), now);
    expect([for (final r in v.groups.single.rows) '${r.task.title}:${r.depth}'], ['pai:0', 'filho:1', 'neto:2']);
    expect(v.groups.single.rows.first.hasChildren, isTrue);
    final collapsed = buildView(s, const ListScope(inboxListId), now, collapsed: {p});
    expect(titles(collapsed), ['pai']);
  });

  test('a completed subtask shows loose in the completed group', () async {
    final p = await repo.createTask(listId: inboxListId, title: 'pai');
    final c = await repo.createTask(listId: inboxListId, title: 'filho', parentId: p);
    await repo.complete(c);
    final v = buildView(await repo.loadSnapshot(), const ListScope(inboxListId), now);
    expect(v.groups.first.rows.single.hasChildren, isFalse);
    expect(v.groups.last.rows.single.task.title, 'filho');
  });

  test('sectioned list: Não Classificado first, then sections in order', () async {
    final list = await repo.createList(name: 'L');
    final doing = await repo.createSection(list, 'Fazendo');
    await repo.createTask(listId: list, title: 'solta');
    await repo.createTask(listId: list, title: 'na seção', sectionId: doing);
    final v = buildView(await repo.loadSnapshot(), ListScope(list), now);
    expect(headers(v), [UnsectionedHeader, SectionHeader]);
    expect((v.groups[1].header as SectionHeader).name, 'Fazendo');
    expect(v.groups[1].sectionId, doing);
  });

  test('Today: overdue + today, grouped by date; tomorrow is out', () async {
    await repo.createTask(listId: inboxListId, title: 'ontem', dueDate: DateTime(2026, 9, 23));
    await repo.createTask(listId: inboxListId, title: 'hoje', dueDate: DateTime(2026, 9, 24, 18, 48), isAllDay: false);
    await repo.createTask(listId: inboxListId, title: 'amanhã', dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: 'sem data');
    final v = buildView(await repo.loadSnapshot(), const SmartScope(SmartList.today), now, options: smartListDefaultOptions);
    expect(headers(v), [OverdueHeader, DayHeader]);
    expect(titles(v), ['ontem', 'hoje']);
    expect(v.addTarget!.dueDate, DateTime(2026, 9, 24));
    expect(v.addTarget!.listId, inboxListId);
  });

  test('Next 7 days: one header per day', () async {
    await repo.createTask(listId: inboxListId, title: 'qui', dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: inboxListId, title: 'sex', dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: 'sáb', dueDate: DateTime(2026, 9, 26));
    await repo.createTask(listId: inboxListId, title: 'longe', dueDate: DateTime(2026, 10, 30));
    final v = buildView(await repo.loadSnapshot(), const SmartScope(SmartList.next7Days), now, options: smartListDefaultOptions);
    expect([for (final g in v.groups) (g.header as DayHeader).day], [DateTime(2026, 9, 24), DateTime(2026, 9, 25), DateTime(2026, 9, 26)]);
  });

  test('lists hidden from smart lists and archived lists stay out of Today', () async {
    final hidden = await repo.createList(name: 'Oculta', showInSmartLists: false);
    final archived = await repo.createList(name: 'Arquivada');
    await repo.createTask(listId: hidden, title: 'a', dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: archived, title: 'b', dueDate: DateTime(2026, 9, 24));
    await repo.archiveList(archived, archived: true);
    final v = buildView(await repo.loadSnapshot(), const SmartScope(SmartList.today), now, options: smartListDefaultOptions);
    expect(v.isEmpty, isTrue);
  });

  test('Completed and Trash views', () async {
    final a = await repo.createTask(listId: inboxListId, title: 'feita');
    await repo.complete(a);
    final b = await repo.createTask(listId: inboxListId, title: 'lixo');
    await repo.delete(b);
    final s = await repo.loadSnapshot();
    final done = buildView(s, const SmartScope(SmartList.completed), now);
    expect((done.groups.single.header as DayHeader).day, DateTime(2026, 9, 24));
    expect(done.addTarget, isNull);
    final trash = buildView(s, const SmartScope(SmartList.trash), now);
    expect(titles(trash), ['lixo']);
    expect(trash.emptyState, EmptyState.trash);
  });

  test('group by priority and sort by title', () async {
    await repo.createTask(listId: inboxListId, title: 'b', priority: Priority.high);
    await repo.createTask(listId: inboxListId, title: 'a', priority: Priority.high);
    await repo.createTask(listId: inboxListId, title: 'c');
    final v = buildView(
      await repo.loadSnapshot(),
      const ListScope(inboxListId),
      now,
      options: const ViewOptions(grouping: Grouping.priority, sorting: Sorting.title),
    );
    expect([for (final g in v.groups) (g.header as PriorityHeader).priority], [Priority.high, Priority.none]);
    expect(titles(v), ['a', 'b', 'c']);
  });

  test('tag view includes tasks with a child tag and targets the Inbox', () async {
    final parent = await repo.createTag('trabalho');
    final child = await repo.createTag('reunião', parentId: parent);
    await repo.createTask(listId: inboxListId, title: 'x', tagIds: [child]);
    final v = buildView(await repo.loadSnapshot(), TagScope(parent), now);
    expect(titles(v), ['x']);
    expect(v.addTarget!.tagId, parent);
    expect(v.addTarget!.hint, isA<AddToTagHint>());
  });

  test('counts include subtasks and follow the smart list rules', () async {
    final p = await repo.createTask(listId: inboxListId, title: 'p', dueDate: DateTime(2026, 9, 24));
    await repo.createTask(listId: inboxListId, title: 'c', parentId: p);
    await repo.createTask(listId: inboxListId, title: 'amanhã', dueDate: DateTime(2026, 9, 25));
    final counts = Counts(await repo.loadSnapshot(), now);
    expect(counts.byList[inboxListId], 3);
    expect(counts.bySmartList[SmartList.today], 1);
    expect(counts.bySmartList[SmartList.tomorrow], 1);
    expect(counts.bySmartList[SmartList.next7Days], 2);
  });

  test('notes list: note empty state and add hint', () async {
    final notes = await repo.createList(name: 'Notas', kind: ListKind.notes);
    final v = buildView(await repo.loadSnapshot(), ListScope(notes), now);
    expect(v.emptyState, EmptyState.notes);
    expect(v.addTarget!.hint, isA<AddNoteHint>());
  });

  test('a task with a duration counts as today while under way and is overdue only after its end', () async {
    // Wednesday to Friday: under way on Thursday (today).
    await repo.createTask(listId: inboxListId, title: 'viagem', startDate: DateTime(2026, 9, 23), dueDate: DateTime(2026, 9, 25));
    // Ended on Wednesday.
    await repo.createTask(listId: inboxListId, title: 'terminou', startDate: DateTime(2026, 9, 21), dueDate: DateTime(2026, 9, 23));
    // Starts on Saturday.
    await repo.createTask(listId: inboxListId, title: 'depois', startDate: DateTime(2026, 9, 26), dueDate: DateTime(2026, 9, 27));
    final s = await repo.loadSnapshot();

    final today = buildView(s, const SmartScope(SmartList.today), now, options: smartListDefaultOptions);
    expect(headers(today), [OverdueHeader, DayHeader]);
    expect(titles(today), ['terminou', 'viagem']);
    // "Posição da seção Atrasadas": Fim.
    expect(headers(buildView(s, const SmartScope(SmartList.today), now, options: smartListDefaultOptions, overdueLast: true)), [
      DayHeader,
      OverdueHeader,
    ]);

    final tomorrow = buildView(s, const SmartScope(SmartList.tomorrow), now, options: smartListDefaultOptions);
    expect(titles(tomorrow), ['viagem']);

    final week = buildView(s, const SmartScope(SmartList.next7Days), now, options: smartListDefaultOptions);
    expect(titles(week), ['terminou', 'viagem', 'depois']);

    final counts = Counts(s, now);
    expect(counts.bySmartList[SmartList.today], 2);
    expect(counts.bySmartList[SmartList.tomorrow], 1);
  });
}
