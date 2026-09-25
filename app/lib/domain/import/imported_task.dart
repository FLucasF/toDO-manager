/// A task read from another app's file, before it is written.
class ImportedTask {
  const ImportedTask({
    required this.title,
    this.folderName,
    this.listName,
    this.sectionName,
    this.content = '',
    this.kind = ImportedKind.text,
    this.items = const [],
    this.tags = const [],
    this.startDate,
    this.dueDate,
    this.isAllDay = true,
    this.reminders = const [],
    this.repeatRule,
    this.priority = 0,
    this.status = ImportedStatus.open,
    this.createdAt,
    this.completedAt,
    this.sourceId,
    this.parentSourceId,
  });

  final String title;
  final String? folderName;

  /// Null: the list chosen for the import.
  final String? listName;
  final String? sectionName;
  final String content;
  final ImportedKind kind;

  /// Checklist items: text and whether they are done.
  final List<(String, bool)> items;
  final List<String> tags;

  /// Local times (midnight for all-day dates).
  final DateTime? startDate;
  final DateTime? dueDate;
  final bool isAllDay;

  /// Triggers such as `-PT15M`.
  final List<String> reminders;

  /// RRULE body without the `RRULE:` prefix.
  final String? repeatRule;

  /// TickTick's codes: 0, 1, 3, 5.
  final int priority;
  final ImportedStatus status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  /// The task's id in the file and its parent's, to rebuild subtasks.
  final String? sourceId;
  final String? parentSourceId;
}

enum ImportedKind { text, note, checklist }

enum ImportedStatus { open, completed, wontDo }

/// Triggers inside a text (`TRIGGER:-PT15M,-P1DT15H`), in the app's format.
List<String> triggersIn(String text) => [
  for (final m in RegExp(r'-?P(?:\d+D)?(?:T(?:\d+H)?(?:\d+M)?(?:\d+S)?)?').allMatches(text))
    if (m.group(0)!.length > 1 && m.group(0) != '-P' && m.group(0) != 'P' && !m.group(0)!.endsWith('T')) m.group(0)!,
];
