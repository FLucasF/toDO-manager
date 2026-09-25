import 'package:appflowy_editor/appflowy_editor.dart';

import '../../app/focus_controller.dart' show focusDuration;
import '../../app/format/date_labels.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/summary.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';
import '../editor/markdown_codec.dart';

/// "20 set - 26 set", "25 set" or "Setembro 2026" for a range ([to] exclusive).
String summaryPeriodTitle(AppLocalizations t, ({DateTime from, DateTime to}) range) {
  final dates = DateLabels(t);
  String short(DateTime d) => '${d.day} ${dates.monthShort(d)}';
  final last = DateTime(range.to.year, range.to.month, range.to.day - 1);
  if (last == range.from) return short(range.from);
  if (range.from.day == 1 && range.to == DateTime(range.from.year, range.from.month + 1)) return dates.monthTitle(range.from);
  return '${short(range.from)} - ${short(last)}';
}

/// The text of the "Resumo": the period's title and its tasks by group, with the chosen
/// fields; with "Tarefas do Próximo Período", the next period's open tasks after it. [markdown] marks
/// the titles as headings, for the report's editor.
String summaryReport(
  AppLocalizations t,
  Snapshot s,
  SummaryConfig c,
  DateTime now, {
  Map<String, TaskFocus> focus = const {},
  bool markdown = false,
}) {
  final today = startOfDay(now);
  final range = summaryRange(c, today);
  final out = StringBuffer();
  _period(out, t, s, c, range, today, focus, markdown);
  if (c.nextPeriod) {
    out.writeln();
    final open = c.statuses.isEmpty
        ? {SummaryStatus.inProgress, SummaryStatus.incomplete}
        : c.statuses.intersection({SummaryStatus.inProgress, SummaryStatus.incomplete});
    _period(out, t, s, c.copyWith(statuses: open.isEmpty ? {SummaryStatus.incomplete} : open), nextSummaryRange(range), today, focus, markdown);
  }
  return out.toString().trimRight();
}

void _period(
  StringBuffer out,
  AppLocalizations t,
  Snapshot s,
  SummaryConfig c,
  ({DateTime from, DateTime to}) range,
  DateTime today,
  Map<String, TaskFocus> focus,
  bool markdown,
) {
  final labels = Labels(t);
  final dates = DateLabels(t);
  String short(DateTime d) => '${d.day} ${dates.monthShort(d)}';
  out.writeln('${markdown ? '# ' : ''}${summaryPeriodTitle(t, range)}');
  final tasks = summaryTasks(s, c, range);
  if (tasks.isEmpty) {
    out
      ..writeln()
      ..writeln(t.summaryEmpty);
    return;
  }

  // Groups in their order.
  final groups = <String, (String, List<Task>)>{};
  void add(String key, String title, Task task) => (groups[key] ??= (title, [])).$2.add(task);
  final statusTitles = {
    SummaryStatus.completed: t.summaryCompleted,
    SummaryStatus.wontDo: t.summaryWontDo,
    SummaryStatus.inProgress: t.summaryInProgress,
    SummaryStatus.incomplete: t.summaryUndone,
  };
  final ordered = switch (c.grouping) {
    SummaryGrouping.status => [
      for (final st in [SummaryStatus.completed, SummaryStatus.wontDo, SummaryStatus.inProgress, SummaryStatus.incomplete])
        for (final task in tasks)
          if (summaryStatusOf(s, task) == st) task,
    ],
    SummaryGrouping.priority => [...tasks]..sort((a, b) => b.priority.code.compareTo(a.priority.code)),
    _ => tasks,
  };
  for (final task in ordered) {
    switch (c.grouping) {
      case SummaryGrouping.status:
        final st = summaryStatusOf(s, task);
        add(st.name, statusTitles[st]!, task);
      case SummaryGrouping.list:
        final list = s.listById[task.listId];
        add(task.listId, list == null ? '?' : labels.listName(list), task);
      case SummaryGrouping.completionDate:
        final done = task.status == TaskStatus.completed ? task.completedAt?.toLocal() : null;
        if (done == null) {
          add('~', t.summaryNotCompleted, task);
        } else {
          final day = startOfDay(done);
          add(day.toIso8601String(), dates.dayHeader(day, today), task);
        }
      case SummaryGrouping.taskDate:
        final due = task.endLocal;
        if (due == null) {
          add('~', t.groupNoDate, task);
        } else {
          final day = startOfDay(due);
          add(day.toIso8601String(), dates.dayHeader(day, today), task);
        }
      case SummaryGrouping.tag:
        final tag = s.tagsOf(task.id).firstOrNull;
        add(tag?.id ?? '~', tag?.name ?? t.groupNoTag, task);
      case SummaryGrouping.priority:
        add('${task.priority.code}', labels.priority(task.priority), task);
    }
  }
  final entries = groups.entries.toList();
  if (c.grouping == SummaryGrouping.completionDate || c.grouping == SummaryGrouping.taskDate) {
    entries.sort((a, b) => a.key.compareTo(b.key));
  }

  void line(Task task, int depth) {
    final f = c.fields;
    final parts = <String>[];
    if (f.contains(SummaryField.status)) {
      parts.add(switch (task.status) {
        TaskStatus.completed => '[x]',
        TaskStatus.wontDo => '[-]',
        TaskStatus.open => '[ ]',
      });
    }
    final done = task.completedAt?.toLocal();
    if (f.contains(SummaryField.completionTime) && task.status == TaskStatus.completed && done != null) parts.add('[${short(done)}]');
    final progress = taskProgress(s, task);
    // Only tasks under way show it ("[33%]"); 0% says nothing.
    if (f.contains(SummaryField.progress) && task.status == TaskStatus.open && progress != null && progress > 0) parts.add('[$progress%]');
    if (f.contains(SummaryField.title)) parts.add(task.title.isEmpty ? t.untitled : task.title);
    final due = task.endLocal;
    if (f.contains(SummaryField.taskTime) && due != null) parts.add('(${dates.detailDate(due, isAllDay: task.isAllDay, today: today)})');
    if (f.contains(SummaryField.tag)) {
      for (final tag in s.tagsOf(task.id)) {
        parts.add('#${tag.name}');
      }
    }
    // "Dados de foco": "[🍅2 · 50m]", or only the time when it was all Cronômetro.
    final x = f.contains(SummaryField.focus) ? focus[task.id] : null;
    if (x != null) {
      final time = focusDuration(
        Duration(seconds: x.seconds),
        hours: t.focusHours,
        minutes: t.focusMins,
      );
      parts.add(x.pomos > 0 ? '[🍅${x.pomos} · $time]' : '[$time]');
    }
    if (f.contains(SummaryField.list) && s.listById[task.listId] != null) parts.add('· ${labels.listName(s.listById[task.listId]!)}');
    if (f.contains(SummaryField.parent) && depth == 0 && task.parentId != null && s.taskById[task.parentId] != null) {
      parts.add('(${t.summaryParent(s.taskById[task.parentId]!.title)})');
    }
    final item = parts.join(' ');
    out.writeln('${'  ' * depth}- ${markdown ? escapeMarkdown(item) : item}');
    if (f.contains(SummaryField.detail)) {
      for (final l in task.content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty)) {
        out.writeln('${'  ' * (depth + 1)}$l');
      }
    }
    for (final child in s.childrenOf(task.id)) {
      if (child.deletedAt == null) line(child, depth + 1);
    }
  }

  for (final e in entries) {
    out
      ..writeln()
      ..writeln(markdown ? '## ${escapeMarkdown(e.value.$1)}' : e.value.$1);
    for (final task in e.value.$2) {
      line(task, 0);
    }
  }
}

/// Names in the report's markdown read as written: "2. Enviar proposta" does not start a numbered
/// list, and `*`, `_` or brackets are not formatting.
String escapeMarkdown(String text) => text
    .replaceAllMapped(RegExp(r'[\\`*_\[\]<>~]'), (m) => '\\${m[0]}')
    .replaceFirstMapped(RegExp(r'^(\d+)([.)])(?=\s|$)'), (m) => '${m[1]}\\${m[2]}')
    .replaceFirstMapped(RegExp(r'^([#>+\-])'), (m) => '\\${m[1]}');

/// The report's editor markdown back to plain text (Copiar, PDF, Imagem, email), read through the same
/// parser as the editor, so it matches what is on screen: headings with a blank line around them,
/// nested items two spaces per level, no formatting marks.
String summaryPlainText(String markdown) {
  final out = <String>[];
  void walk(Iterable<Node> nodes, int depth) {
    var number = 0;
    for (final node in nodes) {
      final text = node.delta?.toPlainText() ?? '';
      final pad = '  ' * depth;
      number = node.type == NumberedListBlockKeys.type ? number + 1 : 0;
      switch (node.type) {
        case HeadingBlockKeys.type:
          if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
          out.add(text);
          // The period's title stands apart from what follows it.
          if (node.attributes[HeadingBlockKeys.level] == 1) out.add('');
        case BulletedListBlockKeys.type:
          out.add('$pad- $text');
        case NumberedListBlockKeys.type:
          out.add('$pad$number. $text');
        case TodoListBlockKeys.type:
          out.add('$pad[${node.attributes[TodoListBlockKeys.checked] == true ? 'x' : ' '}] $text');
        case DividerBlockKeys.type:
          out.add('$pad---');
        default:
          out.add('$pad$text');
      }
      walk(node.children, depth + 1);
    }
  }

  walk(markdownToEditorDocument(markdown).root.children, 0);
  return out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
