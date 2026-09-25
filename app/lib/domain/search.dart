import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'quick_add.dart' show foldForSearch;
import 'snapshot.dart';
import 'task_export.dart';

/// Where the search term was found.
enum SearchField { title, content, checklist }

/// One search result: the task, where the term is and a snippet around it with the
/// match range, so the UI can highlight it.
class SearchHit {
  const SearchHit({required this.task, required this.field, required this.snippet, this.matchStart = 0, this.matchLength = 0});

  final Task task;
  final SearchField field;
  final String snippet;
  final int matchStart;
  final int matchLength;
}

/// Filters of the search page: Listas · Tag · Data · Prioridade · Tipo · Status.
class SearchFilters {
  const SearchFilters({
    this.listIds = const {},
    this.tagIds = const {},
    this.priorities = const {},
    this.kinds = const {},
    this.statuses = const {TaskStatus.open, TaskStatus.completed, TaskStatus.wontDo},
    this.from,
    this.to,
    this.archived = false,
  });

  final Set<String> listIds;
  final Set<String> tagIds;
  final Set<Priority> priorities;
  final Set<TaskKind> kinds;
  final Set<TaskStatus> statuses;

  /// Due date range (local days, inclusive); null = any.
  final DateTime? from;
  final DateTime? to;

  /// "Pesquisar em Arquivados": only the tasks of archived lists (else they are left out).
  final bool archived;
}

/// Tasks (not deleted, in lists that are not deleted) matching [query] in the title, the content or a
/// checklist item, ignoring case and accents. An empty query lists every task. Title
/// matches come first, then the most recently changed.
List<SearchHit> searchTasks(Snapshot s, String query, {SearchFilters filters = const SearchFilters(), int limit = 200}) {
  final q = foldForSearch(query.trim());
  final hits = <SearchHit>[];
  for (final task in s.tasks) {
    final list = s.listById[task.listId];
    if (task.deletedAt != null || list == null || list.deletedAt != null) continue;
    if (!_passes(task, s, filters)) continue;
    if (q.isEmpty) {
      hits.add(SearchHit(task: task, field: SearchField.title, snippet: _plain(task.content)));
      continue;
    }
    final hit =
        _match(task, SearchField.title, task.title, q) ??
        _match(task, SearchField.content, _plain(task.content), q) ??
        s.itemsOf(task.id).map((i) => _match(task, SearchField.checklist, i.title, q)).nonNulls.firstOrNull;
    if (hit != null) hits.add(hit);
  }
  hits.sort((a, b) {
    final byField = a.field.index.compareTo(b.field.index);
    return byField != 0 ? byField : b.task.updatedAt.compareTo(a.task.updatedAt);
  });
  return hits.length > limit ? hits.sublist(0, limit) : hits;
}

bool _passes(Task task, Snapshot s, SearchFilters f) {
  if ((s.listById[task.listId]?.archivedAt != null) != f.archived) return false;
  if (f.listIds.isNotEmpty && !f.listIds.contains(task.listId)) return false;
  if (f.tagIds.isNotEmpty && !s.tagsOf(task.id).any((t) => f.tagIds.contains(t.id))) return false;
  if (f.priorities.isNotEmpty && !f.priorities.contains(task.priority)) return false;
  if (f.kinds.isNotEmpty && !f.kinds.contains(task.kind)) return false;
  if (!f.statuses.contains(task.status)) return false;
  if (f.from != null || f.to != null) {
    final due = task.dueDate?.toLocal();
    if (due == null) return false;
    final day = DateTime(due.year, due.month, due.day);
    if (f.from != null && day.isBefore(f.from!)) return false;
    if (f.to != null && day.isAfter(f.to!)) return false;
  }
  return true;
}

/// Plain text of the content for snippets, on one line.
String _plain(String markdown) => plainTextOf(markdown).replaceAll(RegExp(r'\s+'), ' ');

/// Folding keeps the length (one character each), so positions in the folded text are positions in
/// the original.
SearchHit? _match(Task task, SearchField field, String text, String foldedQuery) {
  final at = foldForSearch(text).indexOf(foldedQuery);
  if (at < 0) return null;
  const context = 40;
  final start = at > context ? at - context : 0;
  final end = (at + foldedQuery.length + context).clamp(0, text.length);
  final prefix = start > 0 ? '…' : '';
  final snippet = '$prefix${text.substring(start, end)}${end < text.length ? '…' : ''}';
  return SearchHit(task: task, field: field, snippet: snippet, matchStart: prefix.length + at - start, matchLength: foldedQuery.length);
}

/// Date chip of the search page: Todos, Esta semana, Próxima Semana, Semana passada,
/// Este mês, Mês passado, Personalizado. Weeks start on Sunday, as the rest of the app.
enum SearchDatePreset { all, thisWeek, nextWeek, lastWeek, thisMonth, lastMonth, custom }

/// Inclusive day range of a preset, or null for [SearchDatePreset.all] and [SearchDatePreset.custom].
({DateTime from, DateTime to})? searchDateRange(SearchDatePreset preset, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  final sunday = startOfWeek(day);
  ({DateTime from, DateTime to}) week(int offset) {
    final from = DateTime(sunday.year, sunday.month, sunday.day + 7 * offset);
    return (from: from, to: DateTime(from.year, from.month, from.day + 6));
  }

  ({DateTime from, DateTime to}) month(int offset) =>
      (from: DateTime(day.year, day.month + offset), to: DateTime(day.year, day.month + offset + 1, 0));

  return switch (preset) {
    SearchDatePreset.all || SearchDatePreset.custom => null,
    SearchDatePreset.thisWeek => week(0),
    SearchDatePreset.nextWeek => week(1),
    SearchDatePreset.lastWeek => week(-1),
    SearchDatePreset.thisMonth => month(0),
    SearchDatePreset.lastMonth => month(-1),
  };
}
