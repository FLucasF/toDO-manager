import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/features/focus/focus_records.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  test('"Exportar": a row per record, oldest first, with the link, the timer and the note', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25)));
    final task = await repo.createTask(listId: inboxListId, title: 'Relatório');
    await repo.addFocusRecord(
      FocusRecordDraft(
        startedAt: DateTime(2026, 9, 25, 9),
        endedAt: DateTime(2026, 9, 25, 9, 25),
        seconds: 1500,
        mode: FocusMode.pomo,
        taskId: task,
        note: 'Revisão; parte 1',
        timerId: 'a',
      ),
      timerId: 'a',
    );
    await repo.addFocusRecord(
      FocusRecordDraft(startedAt: DateTime(2026, 9, 24, 8), endedAt: DateTime(2026, 9, 24, 8, 40), seconds: 2400, mode: FocusMode.stopwatch),
    );
    final csv = focusCsv(AppLocalizationsPt(), await repo.loadSnapshot(), await repo.watchFocusRecords().first, const [
      FocusTimer(id: 'a', name: 'Estudo'),
    ]);
    expect(csv.split('\r\n'), [
      'Início;Fim;Minutos;Modo;Vinculado a;Timer;Nota',
      '24/09/2026 08:00;24/09/2026 08:40;40;Cronômetro;;;',
      '25/09/2026 09:00;25/09/2026 09:25;25;Pomo;Relatório;Estudo;"Revisão; parte 1"',
    ]);
  });
}
