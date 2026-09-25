import 'imported_task.dart';

/// Reads CSV text: commas, quoted fields with commas, quotes (`""`) and line breaks.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == ',') {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

/// TickTick's backup ("Configurações → Conta → Gerar Backup"): a CSV with a few lines about the file,
/// then the header ("Folder Name", "List Name", "Title", "Kind", "Tags", "Content", "Start Date",
/// "Due Date", "Reminder", "Repeat", "Priority", "Status", "Created Time", "Completed Time", "Is All
/// Day", "Column Name", "taskId", "parentId", …) and one row per task. Columns are found by name, so
/// missing or extra ones do not matter. Throws [FormatException] when there is no such header.
List<ImportedTask> parseTickTickBackup(String text) {
  final rows = parseCsv(text.startsWith('﻿') ? text.substring(1) : text);
  final headerAt = rows.indexWhere((r) => r.contains('Title') && (r.contains('List Name') || r.contains('Folder Name')));
  if (headerAt < 0) throw const FormatException('not a TickTick backup');
  final header = rows[headerAt];
  String? cell(List<String> row, String name) {
    final i = header.indexOf(name);
    if (i < 0 || i >= row.length) return null;
    final v = row[i].trim();
    return v.isEmpty ? null : v;
  }

  final tasks = <ImportedTask>[];
  for (final row in rows.skip(headerAt + 1)) {
    if (row.every((c) => c.trim().isEmpty)) continue;
    final title = cell(row, 'Title') ?? '';
    final kind = switch (cell(row, 'Kind')?.toUpperCase()) {
      'NOTE' => ImportedKind.note,
      'CHECKLIST' => ImportedKind.checklist,
      _ => cell(row, 'Is Check list')?.toUpperCase() == 'Y' ? ImportedKind.checklist : ImportedKind.text,
    };
    // Checklist items come in the content, one per line: ▫ open, ▪ done.
    final contentLines = (cell(row, 'Content') ?? '').split('\n');
    final items = <(String, bool)>[];
    final rest = <String>[];
    for (final line in contentLines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('▫') || trimmed.startsWith('▪')) {
        items.add((trimmed.substring(1).trim(), trimmed.startsWith('▪')));
      } else {
        rest.add(line);
      }
    }
    final allDay = switch (cell(row, 'Is All Day')?.toLowerCase()) {
      'true' || 'y' || '1' => true,
      'false' || 'n' || '0' => false,
      _ => null,
    };
    final start = _date(cell(row, 'Start Date'));
    final due = _date(cell(row, 'Due Date')) ?? start;
    final status = switch (cell(row, 'Status')) {
      '1' || '2' => ImportedStatus.completed,
      '-1' => ImportedStatus.wontDo,
      _ => ImportedStatus.open,
    };
    final repeat = cell(row, 'Repeat')?.replaceFirst(RegExp('^RRULE:', caseSensitive: false), '');
    final isAllDay = allDay ?? (due == null || (due.hour == 0 && due.minute == 0));
    DateTime? local(DateTime? d) => d == null ? null : (isAllDay ? DateTime(d.year, d.month, d.day) : d);
    tasks.add(
      ImportedTask(
        title: title,
        folderName: cell(row, 'Folder Name'),
        listName: cell(row, 'List Name'),
        sectionName: cell(row, 'Column Name'),
        content: rest.join('\n').trim(),
        kind: items.isNotEmpty ? ImportedKind.checklist : kind,
        items: items,
        tags: [
          for (final tag in (cell(row, 'Tags') ?? '').split(RegExp(r'[,\s]+')))
            if (tag.replaceFirst('#', '').isNotEmpty) tag.replaceFirst('#', ''),
        ],
        startDate: local(start),
        dueDate: local(due),
        isAllDay: isAllDay,
        reminders: triggersIn(cell(row, 'Reminder') ?? ''),
        repeatRule: repeat == null || repeat.isEmpty ? null : repeat,
        priority: switch (int.tryParse(cell(row, 'Priority') ?? '')) {
          final p? when const {0, 1, 3, 5}.contains(p) => p,
          _ => 0,
        },
        status: status,
        createdAt: _date(cell(row, 'Created Time')),
        completedAt: _date(cell(row, 'Completed Time')),
        sourceId: cell(row, 'taskId'),
        parentSourceId: cell(row, 'parentId'),
      ),
    );
  }
  return tasks;
}

/// "2026-09-25T09:00:00+0000" (TickTick) or ISO 8601, as local time.
DateTime? _date(String? text) {
  if (text == null) return null;
  final normalized = text.replaceFirstMapped(RegExp(r'([+-]\d{2})(\d{2})$'), (m) => '${m[1]}:${m[2]}');
  return DateTime.tryParse(normalized)?.toLocal();
}
