import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/task_export.dart';
import 'package:task_manager/features/tasks/export_print.dart';

void main() {
  test('export as Markdown and plain text', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25)));
    final tag = await repo.createTag('casa');
    final id = await repo.createTask(listId: inboxListId, title: 'Mudança', content: 'Ligar para a **transportadora**', tagIds: [tag]);
    final sub = await repo.createTask(listId: inboxListId, title: 'Caixas', parentId: id);
    await repo.complete(sub);
    final s = await repo.loadSnapshot();
    final task = s.taskById[id]!;

    expect(
      exportTask(s, task, markdown: true, dateLabel: 'Amanhã, 26 set'),
      '# Mudança\nAmanhã, 26 set\n#casa\n\nLigar para a **transportadora**\n\n- [x] Caixas',
    );
    expect(exportTask(s, task, markdown: false), 'Mudança\n#casa\n\nLigar para a transportadora\n\n☑ Caixas');
    await db.close();
  });

  test('the printout PDF builds with Portuguese accents', () async {
    final bytes = await buildPdf('Reunião de orçamento', [pw.Text('[ ] Revisar ações — amanhã, 25 set')]);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
