import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'snapshot.dart';
import 'task_dates.dart';

/// Period of the "Resumo".
enum SummaryDate { today, tomorrow, yesterday, thisWeek, nextWeek, lastWeek, thisMonth, lastMonth, custom }

/// Status filter and groups: Concluído, Em andamento, Incompleta, Não será feito.
enum SummaryStatus { completed, inProgress, incomplete, wontDo }

/// "Agrupamento" of the report.
enum SummaryGrouping { status, list, completionDate, taskDate, tag, priority }

/// "Campos" of each line (the title is always there).
enum SummaryField { status, progress, completionTime, taskTime, title, parent, tag, focus, list, detail }

/// "Dados de foco" of a task: its Pomos and all the time focused on it.
typedef TaskFocus = ({int pomos, int seconds});

/// [TaskFocus] of every task that has focus records.
Map<String, TaskFocus> focusByTask(Iterable<FocusRecord> records) {
  final out = <String, TaskFocus>{};
  for (final r in records) {
    final id = r.taskId;
    if (id == null || r.deletedAt != null) continue;
    final was = out[id] ?? (pomos: 0, seconds: 0);
    out[id] = (pomos: was.pomos + (r.mode == FocusMode.pomo ? 1 : 0), seconds: was.seconds + r.seconds);
  }
  return out;
}

/// Filters and display options of the Resumo; saved as the last one used and as named "Modelos".
class SummaryConfig {
  const SummaryConfig({
    this.date = SummaryDate.thisWeek,
    this.from,
    this.to,
    this.listIds = const {},
    this.statuses = const {},
    this.tagIds = const {},
    this.priorities = const {},
    this.grouping = SummaryGrouping.status,
    this.fields = const {SummaryField.progress, SummaryField.completionTime, SummaryField.title},
    this.nextPeriod = false,
  });

  final SummaryDate date;

  /// "Personalizado": first and last day.
  final DateTime? from;
  final DateTime? to;

  /// Empty = all.
  final Set<String> listIds;
  final Set<SummaryStatus> statuses;
  final Set<String> tagIds;
  final Set<Priority> priorities;
  final SummaryGrouping grouping;
  final Set<SummaryField> fields;

  /// "Tarefas do Próximo Período".
  final bool nextPeriod;

  SummaryConfig copyWith({
    SummaryDate? date,
    DateTime? from,
    DateTime? to,
    Set<String>? listIds,
    Set<SummaryStatus>? statuses,
    Set<String>? tagIds,
    Set<Priority>? priorities,
    SummaryGrouping? grouping,
    Set<SummaryField>? fields,
    bool? nextPeriod,
  }) => SummaryConfig(
    date: date ?? this.date,
    from: from ?? this.from,
    to: to ?? this.to,
    listIds: listIds ?? this.listIds,
    statuses: statuses ?? this.statuses,
    tagIds: tagIds ?? this.tagIds,
    priorities: priorities ?? this.priorities,
    grouping: grouping ?? this.grouping,
    fields: fields ?? this.fields,
    nextPeriod: nextPeriod ?? this.nextPeriod,
  );

  Map<String, Object?> toJson() => {
    'date': date.name,
    if (from != null) 'from': from!.toIso8601String(),
    if (to != null) 'to': to!.toIso8601String(),
    'lists': listIds.toList(),
    'statuses': [for (final s in statuses) s.name],
    'tags': tagIds.toList(),
    'priorities': [for (final p in priorities) p.code],
    'grouping': grouping.name,
    'fields': [for (final f in fields) f.name],
    // Marks a list that already knows "Título da Tarefa"; older ones always showed the title.
    'titleField': true,
    'next': nextPeriod,
  };

  static SummaryConfig fromJson(Object? json) {
    const d = SummaryConfig();
    if (json is! Map<String, Object?>) return d;
    List<Object?> list(String key) => json[key] is List<Object?> ? json[key]! as List<Object?> : const [];
    T? named<T extends Enum>(List<T> values, Object? name) => values.where((v) => v.name == name).firstOrNull;
    DateTime? day(String key) => json[key] is String ? DateTime.tryParse(json[key]! as String) : null;
    return SummaryConfig(
      date: named(SummaryDate.values, json['date']) ?? d.date,
      from: day('from'),
      to: day('to'),
      listIds: {
        for (final v in list('lists'))
          if (v is String) v,
      },
      statuses: {for (final v in list('statuses')) ?named(SummaryStatus.values, v)},
      tagIds: {
        for (final v in list('tags'))
          if (v is String) v,
      },
      priorities: {for (final v in list('priorities')) ?Priority.values.where((p) => p.code == v).firstOrNull},
      grouping: named(SummaryGrouping.values, json['grouping']) ?? d.grouping,
      fields: json.containsKey('fields')
          ? {for (final v in list('fields')) ?named(SummaryField.values, v), if (json['titleField'] != true) SummaryField.title}
          : d.fields,
      nextPeriod: json['next'] == true,
    );
  }
}

/// A named "Modelo" of the Resumo.
class SummaryTemplate {
  const SummaryTemplate(this.name, this.config);

  final String name;
  final SummaryConfig config;

  Map<String, Object?> toJson() => {'name': name, 'config': config.toJson()};

  static SummaryTemplate? fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['name'] is! String) return null;
    return SummaryTemplate(json['name']! as String, SummaryConfig.fromJson(json['config']));
  }
}

/// First day and the day after the last of the period ([to] exclusive).
({DateTime from, DateTime to}) summaryRange(SummaryConfig c, DateTime today) {
  DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);
  final week = startOfWeek(today);
  DateTime weekDay(int offset) => DateTime(week.year, week.month, week.day + offset);
  return switch (c.date) {
    SummaryDate.today => (from: day(0), to: day(1)),
    SummaryDate.tomorrow => (from: day(1), to: day(2)),
    SummaryDate.yesterday => (from: day(-1), to: day(0)),
    SummaryDate.thisWeek => (from: week, to: weekDay(7)),
    SummaryDate.nextWeek => (from: weekDay(7), to: weekDay(14)),
    SummaryDate.lastWeek => (from: weekDay(-7), to: week),
    SummaryDate.thisMonth => (from: DateTime(today.year, today.month), to: DateTime(today.year, today.month + 1)),
    SummaryDate.lastMonth => (from: DateTime(today.year, today.month - 1), to: DateTime(today.year, today.month)),
    SummaryDate.custom => (
      from: startOfDay(c.from ?? today),
      to: () {
        final last = startOfDay(c.to ?? c.from ?? today);
        return DateTime(last.year, last.month, last.day + 1);
      }(),
    ),
  };
}

/// The period right after [range], of the same kind (a month after a month, else the same days).
({DateTime from, DateTime to}) nextSummaryRange(({DateTime from, DateTime to}) range) {
  final isMonth = range.from.day == 1 && range.to.day == 1 && range.to == DateTime(range.from.year, range.from.month + 1);
  if (isMonth) return (from: range.to, to: DateTime(range.to.year, range.to.month + 1));
  final days = daysBetween(range.from, range.to);
  return (from: range.to, to: DateTime(range.to.year, range.to.month, range.to.day + days));
}

/// Progress of a task from 0 to 100: its checklist items, else its subtasks; null when it has none.
int? taskProgress(Snapshot s, Task t) {
  final items = s.itemsOf(t.id);
  if (items.isNotEmpty) return (100 * items.where((i) => i.isCompleted).length / items.length).round();
  final children = s.childrenOf(t.id).where((c) => c.deletedAt == null).toList();
  if (children.isEmpty) return null;
  return (100 * children.where((c) => c.status == TaskStatus.completed).length / children.length).round();
}

SummaryStatus summaryStatusOf(Snapshot s, Task t) => switch (t.status) {
  TaskStatus.completed => SummaryStatus.completed,
  TaskStatus.wontDo => SummaryStatus.wontDo,
  TaskStatus.open => (taskProgress(s, t) ?? 0) > 0 ? SummaryStatus.inProgress : SummaryStatus.incomplete,
};

bool _in(DateTime? at, DateTime from, DateTime to) {
  if (at == null) return false;
  final local = at.toLocal();
  return !local.isBefore(from) && local.isBefore(to);
}

/// Tasks of the report: those closed in the period and the open ones planned for it, after the filters.
/// Subtasks whose parent is also in the report are left out (they go under it).
List<Task> summaryTasks(Snapshot s, SummaryConfig c, ({DateTime from, DateTime to}) range) {
  bool matches(Task t) {
    final list = s.listById[t.listId];
    if (t.deletedAt != null || list == null || list.deletedAt != null) return false;
    if (c.listIds.isNotEmpty && !c.listIds.contains(t.listId)) return false;
    if (c.priorities.isNotEmpty && !c.priorities.contains(t.priority)) return false;
    if (c.tagIds.isNotEmpty && !s.tagsOf(t.id).any((tag) => c.tagIds.contains(tag.id) || c.tagIds.contains(tag.parentId))) return false;
    if (c.statuses.isNotEmpty && !c.statuses.contains(summaryStatusOf(s, t))) return false;
    if (t.status != TaskStatus.open) return _in(t.completedAt, range.from, range.to);
    final start = t.startLocal, end = t.endLocal;
    if (start == null || end == null) return false;
    return !startOfDay(end).isBefore(range.from) && startOfDay(start).isBefore(range.to);
  }

  final picked = s.tasks.where(matches).toList();
  final ids = {for (final t in picked) t.id};
  return [
    for (final t in picked)
      if (t.parentId == null || !ids.contains(t.parentId)) t,
  ]..sort((a, b) {
    final da = a.completedAt ?? a.dueDate, db = b.completedAt ?? b.dueDate;
    if (da != null && db != null && da != db) return da.compareTo(db);
    return a.sortOrder.compareTo(b.sortOrder);
  });
}
