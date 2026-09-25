import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/domain/summary.dart';
import 'package:task_manager/features/summary/summary_text.dart';
import 'package:task_manager/l10n/app_localizations.dart';

class _Clock implements Clock {
  DateTime value = DateTime(2026, 9, 21, 9);

  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late Repository repo;
  late _Clock clock;
  final t = lookupAppLocalizations(const Locale('pt'));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    clock = _Clock();
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  test('ranges: this week, last month, custom and the next period', () {
    final today = DateTime(2026, 9, 25);
    expect(summaryRange(const SummaryConfig(), today), (from: DateTime(2026, 9, 20), to: DateTime(2026, 9, 27)));
    expect(summaryRange(const SummaryConfig(date: SummaryDate.lastMonth), today), (from: DateTime(2026, 8), to: DateTime(2026, 9)));
    final custom = SummaryConfig(date: SummaryDate.custom, from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 3));
    expect(summaryRange(custom, today), (from: DateTime(2026, 9), to: DateTime(2026, 9, 4)));
    expect(nextSummaryRange((from: DateTime(2026, 9, 20), to: DateTime(2026, 9, 27))), (from: DateTime(2026, 9, 27), to: DateTime(2026, 10, 4)));
    expect(nextSummaryRange((from: DateTime(2026, 9), to: DateTime(2026, 10))), (from: DateTime(2026, 10), to: DateTime(2026, 11)));
    final back = SummaryConfig.fromJson(const SummaryConfig(grouping: SummaryGrouping.list, nextPeriod: true, fields: {SummaryField.tag}).toJson());
    expect((back.grouping, back.nextPeriod), (SummaryGrouping.list, true));
    expect(back.fields, {SummaryField.tag});
    // Saved before "Título da Tarefa" existed: the title stays on.
    expect(
      SummaryConfig.fromJson({
        'fields': ['tag'],
      }).fields,
      {SummaryField.tag, SummaryField.title},
    );
    expect(const SummaryConfig().fields, contains(SummaryField.title));
  });

  test('the report groups by status, shows progress and completion day, and nests subtasks', () async {
    final done = await repo.createTask(listId: inboxListId, title: 'Relatório', dueDate: DateTime(2026, 9, 22));
    final trip = await repo.createTask(listId: inboxListId, title: 'Viagem', kind: TaskKind.checklist, dueDate: DateTime(2026, 9, 26));
    final a = await repo.addChecklistItem(trip, title: 'Passaporte');
    await repo.addChecklistItem(trip, title: 'Mala');
    await repo.addChecklistItem(trip, title: 'Hotel');
    await repo.setChecklistItemCompleted(a, completed: true);
    final plan = await repo.createTask(listId: inboxListId, title: 'Planejar', dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: 'Rascunho', parentId: plan);
    await repo.createTask(listId: inboxListId, title: 'Fora do período', dueDate: DateTime(2026, 10, 10));
    clock.value = DateTime(2026, 9, 24, 10);
    await repo.complete(done);

    final s = await repo.loadSnapshot();
    final report = summaryReport(t, s, const SummaryConfig(), DateTime(2026, 9, 25, 12));
    expect(
      report,
      [
        '20 set - 26 set',
        '',
        'Concluído',
        '- [24 set] Relatório',
        '',
        'Em andamento',
        '- [33%] Viagem',
        '',
        'Desfeito',
        '- Planejar',
        '  - Rascunho',
      ].join('\n'),
    );

    // The editor gets the same report as markdown; its plain text is the report above.
    final markdown = summaryReport(t, s, const SummaryConfig(), DateTime(2026, 9, 25, 12), markdown: true);
    expect(markdown, startsWith('# 20 set - 26 set\n\n## Concluído\n- \\[24 set\\] Relatório'));
    expect(summaryPlainText(markdown), report);

    final next = summaryReport(
      t,
      s,
      const SummaryConfig(date: SummaryDate.today, nextPeriod: true, grouping: SummaryGrouping.list),
      DateTime(2026, 9, 25, 12),
    );
    expect(next, ['25 set', '', 'Caixa de Entrada', '- Planejar', '  - Rascunho', '', '26 set', '', 'Caixa de Entrada', '- [33%] Viagem'].join('\n'));

    // "Dados de foco": two Pomos and a Cronômetro on "Planejar".
    DateTime at(int h) => DateTime(2026, 9, 25, h);
    for (final (h, mode, minutes) in [(8, FocusMode.pomo, 25), (9, FocusMode.pomo, 25), (10, FocusMode.stopwatch, 70)]) {
      await repo.addFocusRecord(
        FocusRecordDraft(
          startedAt: at(h),
          endedAt: at(h).add(Duration(minutes: minutes)),
          seconds: minutes * 60,
          mode: mode,
          taskId: plan,
        ),
      );
    }
    final focus = focusByTask(await repo.watchFocusRecords().first);
    expect(focus[plan], (pomos: 2, seconds: 120 * 60));
    final withFocus = summaryReport(
      t,
      s,
      const SummaryConfig(date: SummaryDate.today, fields: {SummaryField.title, SummaryField.focus}),
      DateTime(2026, 9, 25, 12),
      focus: focus,
    );
    expect(withFocus, contains('- Planejar [🍅2 · 2h]'));
    // "Título da Tarefa" can be switched off like the other fields.
    final noTitle = summaryReport(
      t,
      s,
      const SummaryConfig(date: SummaryDate.today, fields: {SummaryField.focus}),
      DateTime(2026, 9, 25, 12),
      focus: focus,
    );
    expect(noTitle, contains('- [🍅2 · 2h]'));
    expect(noTitle, isNot(contains('Planejar')));
  });

  test('the editor markdown goes back to the plain report for Copiar, PDF, Imagem and email', () {
    const md = '# 20 set - 26 set\n## Concluído\n- \\[24 set\\] Pagar **conta_de** luz _hoje_\n\t- Passaporte\n## Desfeito\n- Workshop \\[x\\]';
    expect(summaryPlainText(md), '20 set - 26 set\n\nConcluído\n- [24 set] Pagar conta_de luz hoje\n  - Passaporte\n\nDesfeito\n- Workshop [x]');
  });

  test('names that look like markdown stay as written in the report', () async {
    await repo.createTask(listId: inboxListId, title: '2. Enviar proposta', dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: '__init__ cleanup *urgente* [x]', dueDate: DateTime(2026, 9, 25));
    await repo.createTask(listId: inboxListId, title: '# não é título', dueDate: DateTime(2026, 9, 25));
    final s = await repo.loadSnapshot();
    const config = SummaryConfig(date: SummaryDate.today);
    final plain = summaryReport(t, s, config, DateTime(2026, 9, 25, 12));
    expect(plain, contains('- 2. Enviar proposta'));
    expect(summaryPlainText(summaryReport(t, s, config, DateTime(2026, 9, 25, 12), markdown: true)), plain);
    expect(escapeMarkdown('1) item'), r'1\) item');
  });
}
