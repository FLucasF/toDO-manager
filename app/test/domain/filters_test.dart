import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/filters.dart';
import 'package:task_manager/domain/search.dart';
import 'package:task_manager/domain/views.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  // Friday, 2026-09-25.
  final now = DateTime(2026, 9, 25, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  Future<List<String>> titles(FilterRule rule) async {
    final id = await repo.createFilter('F', rule);
    final view = buildView(await repo.loadSnapshot(), FilterScope(id), now);
    return [
      for (final g in view.groups)
        for (final r in g.rows) r.task.title,
    ]..sort();
  }

  Future<void> seed() async {
    final work = await repo.createList(name: 'Trabalho');
    final tag = await repo.createTag('casa');
    await repo.createTask(listId: inboxListId, title: 'A alta hoje', priority: Priority.high, dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: work, title: 'B alta sem data', priority: Priority.high);
    await repo.createTask(listId: inboxListId, title: 'C casa atrasada', tagIds: [tag], dueDate: DateTime(2026, 9, 20));
    await repo.createTask(listId: work, title: 'D relatório próximo mês', content: 'enviar relatório', dueDate: DateTime(2026, 10, 12));
    final done = await repo.createTask(listId: inboxListId, title: 'E concluída', priority: Priority.high);
    await repo.complete(done);
  }

  test('normal mode: every condition must match; completed tasks never show', () async {
    await seed();
    expect(
      await titles(
        const FilterRule(
          conditions: [
            FilterCondition(field: FilterField.priority, values: {'5'}),
            FilterCondition(field: FilterField.date, values: {'today'}),
          ],
        ),
      ),
      ['A alta hoje'],
    );
    expect(
      await titles(
        const FilterRule(
          conditions: [
            FilterCondition(field: FilterField.date, values: {'noDate'}),
          ],
        ),
      ),
      ['B alta sem data'],
    );
  });

  test('advanced mode: OU, "não é", dates and keyword', () async {
    await seed();
    expect(
      await titles(
        const FilterRule(
          advanced: true,
          any: true,
          conditions: [
            FilterCondition(field: FilterField.date, values: {'overdue'}),
            FilterCondition(field: FilterField.date, values: {'nextMonth'}),
          ],
        ),
      ),
      ['C casa atrasada', 'D relatório próximo mês'],
    );
    expect(
      await titles(
        const FilterRule(
          conditions: [
            FilterCondition(field: FilterField.priority, values: {'5'}, negate: true),
          ],
        ),
      ),
      ['C casa atrasada', 'D relatório próximo mês'],
    );
    expect(await titles(const FilterRule(keyword: 'relatorio')), ['D relatório próximo mês']);
  });

  test('"Salvar como filtro" keeps the search chips; rules survive encoding', () {
    final rule = FilterRule.fromSearch('pão', const SearchFilters(priorities: {Priority.high}, kinds: {TaskKind.note}));
    final back = FilterRule.decode(rule.encode());
    expect(back.keyword, 'pão');
    expect(back.conditions.map((c) => (c.field, c.values.join(','))), [(FilterField.priority, '5'), (FilterField.kind, 'NOTE')]);
    expect(FilterRule.decode('not json').conditions, isEmpty);
  });
}
