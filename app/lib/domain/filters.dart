import 'dart:convert';

import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'quick_add.dart' show foldForSearch;
import 'search.dart';
import 'snapshot.dart';
import 'task_dates.dart';

/// Fields a filter condition looks at.
enum FilterField { list, tag, date, priority, kind }

/// Date values of a filter: Atrasadas, Hoje, Amanhã, Esta semana, Próxima semana, Este mês, Próximo
/// mês, Sem data.
enum FilterDate { overdue, today, tomorrow, thisWeek, nextWeek, thisMonth, nextMonth, noDate }

/// One condition: the field "é" (or "não é") one of [values]. Values are list ids, tag ids,
/// [FilterDate] names, priority codes or kind codes, as text.
class FilterCondition {
  const FilterCondition({required this.field, required this.values, this.negate = false});

  final FilterField field;
  final Set<String> values;
  final bool negate;

  Map<String, Object> toJson() => {'field': field.name, 'values': values.toList(), if (negate) 'not': true};

  static FilterCondition? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final field = FilterField.values.where((f) => f.name == json['field']).firstOrNull;
    final values = json['values'];
    if (field == null || values is! List<Object?>) return null;
    return FilterCondition(
      field: field,
      values: {
        for (final v in values)
          if (v is String) v,
      },
      negate: json['not'] == true,
    );
  }
}

/// A custom filter (smart list). "Normal" joins its conditions with E; "Avançado" can use OU.
class FilterRule {
  const FilterRule({this.conditions = const [], this.any = false, this.keyword = '', this.advanced = false});

  final List<FilterCondition> conditions;

  /// OU instead of E (advanced mode).
  final bool any;
  final String keyword;
  final bool advanced;

  String encode() => jsonEncode({
    'conditions': [for (final c in conditions) c.toJson()],
    'any': any,
    'keyword': keyword,
    'advanced': advanced,
  });

  static FilterRule decode(String text) {
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return const FilterRule();
      final conditions = json['conditions'];
      return FilterRule(
        conditions: [
          if (conditions is List<Object?>)
            for (final c in conditions) ?FilterCondition.fromJson(c),
        ],
        any: json['any'] == true,
        keyword: json['keyword'] is String ? json['keyword']! as String : '',
        advanced: json['advanced'] == true,
      );
    } on FormatException {
      return const FilterRule();
    }
  }

  /// A filter from the search page's chips ("Salvar como filtro").
  static FilterRule fromSearch(String keyword, SearchFilters f, {FilterDate? date}) => FilterRule(
    keyword: keyword.trim(),
    conditions: [
      if (date != null) FilterCondition(field: FilterField.date, values: {date.name}),
      if (f.listIds.isNotEmpty) FilterCondition(field: FilterField.list, values: f.listIds),
      if (f.tagIds.isNotEmpty) FilterCondition(field: FilterField.tag, values: f.tagIds),
      if (f.priorities.isNotEmpty) FilterCondition(field: FilterField.priority, values: {for (final p in f.priorities) '${p.code}'}),
      if (f.kinds.isNotEmpty) FilterCondition(field: FilterField.kind, values: {for (final k in f.kinds) k.code}),
    ],
  );
}

/// Whether [t] falls on [d] ("Atrasadas", "Hoje", …), [today] being today.
bool taskOnFilterDate(Task t, FilterDate d, DateTime today) => _dateMatches(t, d, today);

bool _dateMatches(Task t, FilterDate d, DateTime today) {
  final toStart = t.daysToStart(today), toEnd = t.daysToEnd(today);
  if (d == FilterDate.noDate) return toEnd == null;
  if (toStart == null || toEnd == null) return false;
  final due = t.endLocal!;
  final sunday = startOfWeek(today);
  bool inRange(DateTime from, DateTime to) => !due.isBefore(from) && due.isBefore(to);
  return switch (d) {
    FilterDate.overdue => toEnd < 0,
    FilterDate.today => toStart <= 0 && toEnd >= 0,
    FilterDate.tomorrow => t.isOn(today.add(const Duration(days: 1))),
    FilterDate.thisWeek => inRange(sunday, sunday.add(const Duration(days: 7))),
    FilterDate.nextWeek => inRange(sunday.add(const Duration(days: 7)), sunday.add(const Duration(days: 14))),
    FilterDate.thisMonth => due.year == today.year && due.month == today.month,
    FilterDate.nextMonth => inRange(DateTime(today.year, today.month + 1), DateTime(today.year, today.month + 2)),
    FilterDate.noDate => false,
  };
}

bool _conditionMatches(Snapshot s, Task t, FilterCondition c, DateTime today) {
  final hit = switch (c.field) {
    FilterField.list => c.values.contains(t.listId),
    FilterField.tag => s.tagsOf(t.id).any((tag) => c.values.contains(tag.id) || (tag.parentId != null && c.values.contains(tag.parentId))),
    FilterField.priority => c.values.contains('${t.priority.code}'),
    FilterField.kind => c.values.contains(t.kind.code) || (t.kind == TaskKind.checklist && c.values.contains(TaskKind.text.code)),
    FilterField.date => c.values.any((v) => FilterDate.values.where((d) => d.name == v).any((d) => _dateMatches(t, d, today))),
  };
  return c.negate ? !hit : hit;
}

/// Whether an open task in a smart-list list passes the filter.
bool filterMatches(Snapshot s, Task t, FilterRule rule, DateTime now) {
  if (!Snapshot.isOpen(t) || !s.inSmartLists(t)) return false;
  final keyword = foldForSearch(rule.keyword.trim());
  if (keyword.isNotEmpty && !foldForSearch('${t.title} ${t.content}').contains(keyword)) return false;
  final active = rule.conditions.where((c) => c.values.isNotEmpty).toList();
  if (active.isEmpty) return true;
  final today = startOfDay(now);
  bool test(FilterCondition c) => _conditionMatches(s, t, c, today);
  return rule.any && rule.advanced ? active.any(test) : active.every(test);
}
