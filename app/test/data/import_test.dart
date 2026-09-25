import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/importer.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/import/ical.dart';
import 'package:task_manager/domain/import/imported_task.dart';
import 'package:task_manager/domain/import/ticktick_csv.dart';

/// The shape of TickTick's "Gerar Backup" CSV: lines about the file, then the header and the tasks.
const _backup = '''
"Date: 2026-09-25+0000"
"Version: 7.1"
"Status:
0 Normal
1 Completed
2 Archived"
"Folder Name","List Name","Title","Kind","Tags","Content","Is Check list","Start Date","Due Date","Reminder","Repeat","Priority","Status","Created Time","Completed Time","Order","Timezone","Is All Day","Is Floating","Column Name","Column Order","View Mode","taskId","parentId"
"Trabalho","Projetos","Relatório, parte 1","TEXT","clone, urgente","Primeira linha
Segunda linha","N","","2026-09-26T12:00:00+0000","TRIGGER:-PT15M","RRULE:FREQ=WEEKLY;INTERVAL=1","5","0","2026-09-20T10:00:00+0000","","1","America/Sao_Paulo","false","false","Fazendo","0","list","t1",""
"Trabalho","Projetos","Revisar ""números""","TEXT","","","N","","","","","0","0","","","2","","","","","","","t2","t1"
"","Inbox","Viagem","CHECKLIST","","▪Passaporte
▫Mala","Y","","","","","3","2","","2026-09-24T18:00:00+0000","3","","true","","","","","t3",""
''';

const _ics = '''
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
SUMMARY:Pagar conta\\, luz
DESCRIPTION:Vence amanhã\\ncom juros
DUE;VALUE=DATE:20260926
PRIORITY:1
CATEGORIES:Casa,Contas
BEGIN:VALARM
TRIGGER:-PT1H
END:VALARM
END:VTODO
BEGIN:VEVENT
SUMMARY:Reunião longa com o time de produto e com o c
 liente
DTSTART:20260927T130000Z
DTEND:20260927T150000Z
STATUS:CANCELLED
END:VEVENT
BEGIN:VEVENT
SUMMARY:Feriado
DTSTART;VALUE=DATE:20261012
DTEND;VALUE=DATE:20261013
END:VEVENT
END:VCALENDAR
''';

void main() {
  test('CSV: quoted commas, quotes and line breaks', () {
    expect(parseCsv('a,"b,c","d ""e""",\n"x\ny",z'), [
      ['a', 'b,c', 'd "e"', ''],
      ['x\ny', 'z'],
    ]);
  });

  test("TickTick's backup: lists, tags, dates, reminders, repetition, checklist and status", () {
    final tasks = parseTickTickBackup(_backup);
    expect(tasks.length, 3);
    final report = tasks[0];
    expect((report.folderName, report.listName, report.sectionName, report.title), ('Trabalho', 'Projetos', 'Fazendo', 'Relatório, parte 1'));
    expect(report.tags, ['clone', 'urgente']);
    expect(report.content, 'Primeira linha\nSegunda linha');
    expect((report.isAllDay, report.dueDate, report.priority), (false, DateTime.utc(2026, 9, 26, 12).toLocal(), 5));
    expect(report.reminders, ['-PT15M']);
    expect(report.repeatRule, 'FREQ=WEEKLY;INTERVAL=1');
    expect((tasks[1].title, tasks[1].parentSourceId), ('Revisar "números"', 't1'));
    final trip = tasks[2];
    expect((trip.kind, trip.status, trip.content), (ImportedKind.checklist, ImportedStatus.completed, ''));
    expect(trip.items, [('Passaporte', true), ('Mala', false)]);
    expect(() => parseTickTickBackup('a,b\n1,2'), throwsFormatException);
  });

  test('iCal: to-dos and events, folded lines, all-day and UTC dates, alarms, priority and status', () {
    final tasks = parseICal(_ics);
    expect(tasks.map((t) => t.title), ['Pagar conta, luz', 'Reunião longa com o time de produto e com o cliente', 'Feriado']);
    final bill = tasks[0];
    expect((bill.content, bill.dueDate, bill.isAllDay, bill.priority), ('Vence amanhã\ncom juros', DateTime(2026, 9, 26), true, 5));
    expect(bill.tags, ['Casa', 'Contas']);
    expect(bill.reminders, ['-PT1H']);
    final meeting = tasks[1];
    expect(
      (meeting.startDate, meeting.dueDate, meeting.isAllDay, meeting.status),
      (DateTime.utc(2026, 9, 27, 13).toLocal(), DateTime.utc(2026, 9, 27, 15).toLocal(), false, ImportedStatus.wontDo),
    );
    // An all-day event's DTEND is the next day.
    expect((tasks[2].startDate, tasks[2].dueDate), (DateTime(2026, 10, 12), DateTime(2026, 10, 12)));
    expect(() => parseICal('hello'), throwsFormatException);
  });

  test('import: lists, folders, sections and tags by name; subtasks; completed with their date', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
    await repo.createList(name: 'projetos');
    final result = await importTasks(repo, parseTickTickBackup(_backup));
    expect((result.tasks, result.lists), (3, 0));

    final s = await repo.loadSnapshot();
    expect(s.activeLists.where((l) => l.name.toLowerCase() == 'projetos').length, 1, reason: 'the existing list is reused');
    final report = s.tasks.singleWhere((t) => t.title == 'Relatório, parte 1');
    expect(s.sections.singleWhere((x) => x.id == report.sectionId).name, 'Fazendo');
    expect({for (final tag in s.tagsOf(report.id)) tag.name}, {'clone', 'urgente'});
    expect(s.remindersOf(report.id), ['-PT15M']);
    expect(s.tasks.singleWhere((t) => t.title == 'Revisar "números"').parentId, report.id);
    final trip = s.tasks.singleWhere((t) => t.title == 'Viagem');
    expect((trip.listId, trip.status, trip.completedAt?.toLocal()), (inboxListId, TaskStatus.completed, DateTime.utc(2026, 9, 24, 18).toLocal()));
    expect(s.itemsOf(trip.id).map((i) => (i.title, i.isCompleted)), [('Passaporte', true), ('Mala', false)]);

    final ical = await importTasks(repo, parseICal(_ics), defaultListId: report.listId);
    expect((ical.tasks, ical.lists), (3, 0));
  });
}
