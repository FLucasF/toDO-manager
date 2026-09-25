import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/format/date_labels.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/domain/calendar.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/features/calendar/calendar_details_popup.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  final dates = DateLabels(AppLocalizationsPt());
  final today = DateTime(2026, 9, 25);

  Task task({required DateTime due, DateTime? start}) => Task(
    id: 't',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    listId: 'inbox',
    title: 'Teste',
    content: '',
    kind: TaskKind.text,
    status: TaskStatus.open,
    priority: Priority.none,
    dueDate: due.toUtc(),
    startDate: (start ?? due).toUtc(),
    isAllDay: false,
    isFloating: false,
    progress: 0,
    sortOrder: 0,
  );

  test('the details popup says when: a length, or a point in time alone', () {
    final point = task(due: DateTime(2026, 9, 25, 20, 47));
    // A task at a point in time is drawn half an hour long, but has no end.
    final drawn = CalendarEntry(
      kind: CalendarEntryKind.task,
      id: 't',
      title: 'Teste',
      start: DateTime(2026, 9, 25, 20, 47),
      end: DateTime(2026, 9, 25, 21, 17),
      isAllDay: false,
      task: point,
    );
    expect(calendarWhen(dates, drawn, today), 'Sexta-feira, 25 de setembro · 20:47');

    final meeting = task(start: DateTime(2026, 9, 25, 9), due: DateTime(2026, 9, 25, 10));
    final block = CalendarEntry(
      kind: CalendarEntryKind.task,
      id: 't',
      title: 'Teste',
      start: DateTime(2026, 9, 25, 9),
      end: DateTime(2026, 9, 25, 10),
      isAllDay: false,
      task: meeting,
    );
    expect(calendarWhen(dates, block, today), 'Sexta-feira, 25 de setembro · 09:00 – 10:00');
  });
}
