import 'package:drift/drift.dart' show Value;

import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'filters.dart';
import 'search.dart';
import 'snapshot.dart';
import 'task_dates.dart';
import 'views.dart';

/// "Agrupar por" of a quadrant; Tempo by default.
enum QuadrantGrouping { time, list, priority, tag, none }

/// "Ordenar por" of a quadrant; Tempo by default.
enum QuadrantSorting { time, title, priority, tag }

/// Rule of one quadrant of the Eisenhower Matrix ("Editar Matriz"): which tasks it shows.
/// Empty sets mean "Todas".
class QuadrantRule {
  const QuadrantRule({
    this.name,
    this.icon,
    this.priorities = const {},
    this.listIds = const {},
    this.tagIds = const {},
    this.kinds = const {},
    this.dates = const {},
    this.excludeDates = false,
    this.grouping = QuadrantGrouping.time,
    this.sorting = QuadrantSorting.time,
    this.ascending = true,
  });

  /// Custom name; null = the default name of the quadrant.
  final String? name;

  /// Emoji before the name ("ícone + nome do quadrante"); null = the roman numeral.
  final String? icon;
  final Set<Priority> priorities;
  final Set<String> listIds;
  final Set<String> tagIds;
  final Set<TaskKind> kinds;

  /// "Data": the task's date is one of these ("é") or, with [excludeDates], none of
  /// them ("não é"); empty = any date.
  final Set<FilterDate> dates;
  final bool excludeDates;
  final QuadrantGrouping grouping;
  final QuadrantSorting sorting;

  /// "Ordem": Crescente (true) or Decrescente.
  final bool ascending;

  /// The same filters with another grouping, sorting or order.
  QuadrantRule withView({QuadrantGrouping? grouping, QuadrantSorting? sorting, bool? ascending}) => QuadrantRule(
    name: name,
    icon: icon,
    priorities: priorities,
    listIds: listIds,
    tagIds: tagIds,
    kinds: kinds,
    dates: dates,
    excludeDates: excludeDates,
    grouping: grouping ?? this.grouping,
    sorting: sorting ?? this.sorting,
    ascending: ascending ?? this.ascending,
  );

  /// TickTick's defaults: Alta, Média, Baixa, Nenhuma.
  static const defaults = [
    QuadrantRule(priorities: {Priority.high}),
    QuadrantRule(priorities: {Priority.medium}),
    QuadrantRule(priorities: {Priority.low}),
    QuadrantRule(priorities: {Priority.none}),
  ];

  /// "Tempo + prioridade": priority is importance (Alta, Média) and the date urgency
  /// (Atrasadas, Hoje, Amanhã); tasks move to "urgente" by themselves as their date comes.
  static const _urgent = {FilterDate.overdue, FilterDate.today, FilterDate.tomorrow};
  static const timeAndPriority = [
    QuadrantRule(priorities: {Priority.high, Priority.medium}, dates: _urgent),
    QuadrantRule(priorities: {Priority.high, Priority.medium}, dates: _urgent, excludeDates: true),
    QuadrantRule(priorities: {Priority.low, Priority.none}, dates: _urgent),
    QuadrantRule(priorities: {Priority.low, Priority.none}, dates: _urgent, excludeDates: true),
  ];

  /// Whether the date of [t] passes the "Data" rule.
  bool matchesDate(Task t, DateTime today) {
    if (dates.isEmpty) return true;
    final hit = dates.any((d) => taskOnFilterDate(t, d, today));
    return excludeDates ? !hit : hit;
  }

  Map<String, Object?> toJson() => {
    if (name != null) 'name': name,
    if (icon != null) 'icon': icon,
    'priorities': [for (final p in priorities) p.code],
    'lists': listIds.toList(),
    'tags': tagIds.toList(),
    'kinds': [for (final k in kinds) k.code],
    'dates': [for (final d in dates) d.name],
    if (excludeDates) 'notDates': true,
    'group': grouping.name,
    'sort': sorting.name,
    'asc': ascending,
  };

  static QuadrantRule fromJson(Object? json, QuadrantRule fallback) {
    if (json is! Map<String, Object?>) return fallback;
    List<Object?> list(String key) => json[key] is List<Object?> ? json[key]! as List<Object?> : const [];
    return QuadrantRule(
      name: json['name'] is String ? json['name']! as String : null,
      icon: json['icon'] is String ? json['icon']! as String : null,
      priorities: {
        for (final c in list('priorities'))
          if (c is int) Priority.values.where((p) => p.code == c).firstOrNull,
      }.nonNulls.toSet(),
      listIds: {
        for (final c in list('lists'))
          if (c is String) c,
      },
      tagIds: {
        for (final c in list('tags'))
          if (c is String) c,
      },
      kinds: {
        for (final c in list('kinds'))
          if (c is String) TaskKind.values.where((k) => k.code == c).firstOrNull,
      }.nonNulls.toSet(),
      dates: {
        for (final c in list('dates'))
          if (c is String) FilterDate.values.where((d) => d.name == c).firstOrNull,
      }.nonNulls.toSet(),
      excludeDates: json['notDates'] == true,
      grouping: QuadrantGrouping.values.where((g) => g.name == json['group']).firstOrNull ?? QuadrantGrouping.time,
      sorting: QuadrantSorting.values.where((o) => o.name == json['sort']).firstOrNull ?? QuadrantSorting.time,
      ascending: json['asc'] != false,
    );
  }
}

/// Open (and, unless hidden, completed) top-level tasks of a quadrant, soonest first, tasks without
/// a date last.
List<Task> quadrantTasks(Snapshot s, QuadrantRule rule, {bool hideCompleted = true, DateTime? now}) {
  final today = startOfDay(now ?? DateTime.now());
  final hits = searchTasks(
    s,
    '',
    limit: 100000,
    filters: SearchFilters(
      listIds: rule.listIds,
      tagIds: rule.tagIds,
      priorities: rule.priorities,
      kinds: rule.kinds,
      statuses: hideCompleted ? const {TaskStatus.open} : const {TaskStatus.open, TaskStatus.completed},
    ),
  );
  final tasks = [
    for (final h in hits)
      if (h.task.parentId == null && s.inSmartLists(h.task) && rule.matchesDate(h.task, today)) h.task,
  ];
  int byTime(Task a, Task b) {
    final da = a.startDate ?? a.dueDate, db = b.startDate ?? b.dueDate;
    if (da == null && db == null) return a.sortOrder.compareTo(b.sortOrder);
    // Tasks without a date stay last in either order.
    if (da == null) return rule.ascending ? 1 : -1;
    if (db == null) return rule.ascending ? -1 : 1;
    return da.compareTo(db);
  }

  String firstTag(Task t) => s.tagsOf(t.id).map((tag) => tag.name.toLowerCase()).firstOrNull ?? '\u{10FFFF}';
  int compare(Task a, Task b) => switch (rule.sorting) {
    QuadrantSorting.time => byTime(a, b),
    QuadrantSorting.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    // Crescente = Alta first, as in the list's "Prioridade".
    QuadrantSorting.priority => b.priority.code.compareTo(a.priority.code),
    QuadrantSorting.tag => firstTag(a).compareTo(firstTag(b)),
  };
  tasks.sort((a, b) {
    final pin = (b.pinnedAt != null ? 1 : 0).compareTo(a.pinnedAt != null ? 1 : 0);
    if (pin != 0) return pin;
    final c = compare(a, b);
    return rule.ascending ? c : -c;
  });
  return tasks;
}

/// Dropping [task] on a quadrant: the priority and the day that make it fit [rule]
/// (null = keep it): the highest priority of the rule, and the first day from today that passes the
/// "Data" rule.
({Priority? priority, DateTime? day}) quadrantDrop(Task task, QuadrantRule rule, DateTime today) {
  final priority = rule.priorities.isEmpty || rule.priorities.contains(task.priority)
      ? null
      : rule.priorities.reduce((a, b) => a.code >= b.code ? a : b);
  DateTime? day;
  if (!rule.matchesDate(task, today)) {
    for (var offset = 0; offset < 400 && day == null; offset++) {
      final candidate = DateTime(today.year, today.month, today.day + offset);
      final moved = task.copyWith(dueDate: Value(candidate.toUtc()), startDate: Value(candidate.toUtc()), isAllDay: true);
      if (rule.matchesDate(moved, today)) day = candidate;
    }
  }
  return (priority: priority, day: day);
}

/// Groups of a quadrant, in the order of [tasks] for Tempo: Fixado, Atrasadas, the day,
/// Sem Data; or by list, priority or tag; or none.
List<(GroupHeader, List<Task>)> groupQuadrant(Snapshot s, List<Task> tasks, DateTime now, {QuadrantGrouping grouping = QuadrantGrouping.time}) {
  final today = startOfDay(now);
  final groups = <String, (GroupHeader, List<Task>)>{};
  void add(String key, GroupHeader header, Task t) => (groups[key] ??= (header, [])).$2.add(t);
  for (final t in tasks) {
    switch (grouping) {
      case QuadrantGrouping.none:
        add('all', const NoHeader(), t);
      case QuadrantGrouping.time:
        final toEnd = t.daysToEnd(today), toStart = t.daysToStart(today);
        if (t.pinnedAt != null) {
          add('pinned', const PinnedHeader(), t);
        } else if (toEnd == null || toStart == null) {
          add('none', const NoDateHeader(), t);
        } else if (toEnd < 0) {
          add('overdue', const OverdueHeader(), t);
        } else {
          final day = today.add(Duration(days: toStart < 0 ? 0 : toStart));
          add(day.toIso8601String(), DayHeader(day), t);
        }
      case QuadrantGrouping.list:
        add('list:${t.listId}', ListHeader(t.listId), t);
      case QuadrantGrouping.priority:
        add('priority:${t.priority.code}', PriorityHeader(t.priority), t);
      case QuadrantGrouping.tag:
        final tag = s.tagsOf(t.id).firstOrNull;
        add(tag == null ? 'notag' : 'tag:${tag.id}', tag == null ? const NoTagHeader() : TagHeader(tag.name), t);
    }
  }
  final result = groups.values.toList();
  // Priority groups go Alta → Nenhuma; the others keep the tasks' order.
  if (grouping == QuadrantGrouping.priority) {
    int code(GroupHeader h) => h is PriorityHeader ? h.priority.code : -1;
    result.sort((a, b) => code(b.$1).compareTo(code(a.$1)));
  }
  return result;
}
