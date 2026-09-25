import '../data/db/database.dart';
import 'enums.dart';
import 'snapshot.dart';

/// Markdown without its markup: links keep their text, images and attachments go away. Used by the
/// search snippets and the plain-text export.
String plainTextOf(String markdown) => markdown
    .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
    .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1)!)
    .replaceAll(RegExp(r'^\s{0,3}(#{1,6}|[-*+]|\d+\.|>|- \[[ xX]\])\s+', multiLine: true), '')
    .replaceAll(RegExp(r'[*_`~]{1,3}'), '')
    .trim();

/// "Export" of a task: Markdown or plain text with the title, the date line, the tags,
/// the content, the checklist and the subtasks. [dateLabel] is the localized date ("Hoje, 25 set").
String exportTask(Snapshot s, Task task, {required bool markdown, String? dateLabel, String untitled = ''}) {
  final lines = <String>[];
  final title = task.title.isEmpty ? untitled : task.title;
  final done = task.status == TaskStatus.completed;
  lines.add(markdown ? '# $title' : title);
  if (dateLabel != null) lines.add(dateLabel);
  final tags = s.tagsOf(task.id);
  if (tags.isNotEmpty) lines.add(tags.map((t) => '#${t.name}').join(' '));
  if (task.content.trim().isNotEmpty) {
    lines
      ..add('')
      ..add(markdown ? task.content.trim() : plainTextOf(task.content));
  }
  final items = s.itemsOf(task.id);
  if (items.isNotEmpty) {
    lines.add('');
    for (final i in items) {
      lines.add(markdown ? '- [${i.isCompleted ? 'x' : ' '}] ${i.title}' : '${i.isCompleted ? '☑' : '☐'} ${i.title}');
    }
  }
  void subtasks(String parentId, int depth) {
    for (final c in s.childrenOf(parentId)) {
      final indent = '  ' * depth;
      final closed = c.status != TaskStatus.open;
      final name = c.title.isEmpty ? untitled : c.title;
      lines.add(markdown ? '$indent- [${closed ? 'x' : ' '}] $name' : '$indent${closed ? '☑' : '☐'} $name');
      subtasks(c.id, depth + 1);
    }
  }

  if (s.childrenOf(task.id).isNotEmpty) {
    lines.add('');
    subtasks(task.id, 0);
  }
  final text = lines.join('\n');
  return done && markdown ? text.replaceFirst('# $title', '# ~~$title~~') : text;
}
