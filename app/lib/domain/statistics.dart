import 'dart:math' as math;

import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'focus.dart';
import 'habits.dart';
import 'snapshot.dart';
import 'task_dates.dart';

/// Period of the statistics' charts and of the Tarefa tab: Dia, Semana, Mês.
enum StatsPeriod { day, week, month }

/// First day of the period that holds [day] (weeks start on the "Dia de início da semana").
DateTime periodStart(StatsPeriod p, DateTime day) => switch (p) {
  StatsPeriod.day => startOfDay(day),
  StatsPeriod.week => startOfWeek(day),
  StatsPeriod.month => DateTime(day.year, day.month),
};

/// First day after the period that starts at [start].
DateTime periodEnd(StatsPeriod p, DateTime start) => switch (p) {
  StatsPeriod.day => DateTime(start.year, start.month, start.day + 1),
  StatsPeriod.week => DateTime(start.year, start.month, start.day + 7),
  StatsPeriod.month => DateTime(start.year, start.month + 1),
};

/// The [count] periods ending with the one that holds [day], oldest first.
List<DateTime> recentPeriods(StatsPeriod p, DateTime day, {int count = 7}) {
  var start = periodStart(p, day);
  final starts = <DateTime>[start];
  for (var i = 1; i < count; i++) {
    start = periodStart(p, DateTime(start.year, start.month, start.day - 1));
    starts.add(start);
  }
  return starts.reversed.toList();
}

bool _within(DateTime? at, DateTime from, DateTime to) {
  if (at == null) return false;
  final local = at.toLocal();
  return !local.isBefore(from) && local.isBefore(to);
}

/// Tasks that count: not in the Trash, in an existing list.
Iterable<Task> _live(Snapshot s) => s.tasks.where((t) => t.deletedAt == null && s.listById[t.listId]?.deletedAt == null);

/// Tasks completed between [from] and [to].
List<Task> completedBetween(Snapshot s, DateTime from, DateTime to) => [
  for (final t in _live(s))
    if (t.status == TaskStatus.completed && _within(t.completedAt, from, to)) t,
];

/// Tasks planned for the period: due between [from] and [to] (the "planejadas" of the completion rate).
List<Task> plannedBetween(Snapshot s, DateTime from, DateTime to) => [
  for (final t in _live(s))
    if (t.status != TaskStatus.wontDo && _within(t.dueDate, from, to)) t,
];

/// "Taxa de conclusão" = concluídas ÷ planejadas, 0 to 1; null without planned tasks.
double? completionRate(Snapshot s, DateTime from, DateTime to) {
  final planned = plannedBetween(s, from, to);
  if (planned.isEmpty) return null;
  return planned.where((t) => t.status == TaskStatus.completed).length / planned.length;
}

/// "Distribuição da taxa de conclusão": planned tasks done on time, done late, and not done.
({int onTime, int late, int undone}) completionDistribution(Snapshot s, DateTime from, DateTime to) {
  var onTime = 0, late = 0, undone = 0;
  for (final t in plannedBetween(s, from, to)) {
    if (t.status != TaskStatus.completed) {
      undone++;
    } else if (_onTime(t)) {
      onTime++;
    } else {
      late++;
    }
  }
  return (onTime: onTime, late: late, undone: undone);
}

bool _onTime(Task t) {
  final done = t.completedAt?.toLocal(), end = t.endLocal;
  if (done == null || end == null) return true;
  return !startOfDay(done).isAfter(startOfDay(end));
}

/// How statistics group tasks and focus: by list, tag, priority or task.
enum StatsGrouping { list, tag, priority, task }

/// Completed tasks of the period by list, tag or priority (keys: list id, tag id or priority code),
/// most first.
List<(String, int)> completedBy(Snapshot s, DateTime from, DateTime to, StatsGrouping g) {
  final counts = <String, int>{};
  for (final t in completedBetween(s, from, to)) {
    final keys = switch (g) {
      StatsGrouping.list => [t.listId],
      StatsGrouping.tag => [for (final tag in s.tagsOf(t.id)) tag.id],
      StatsGrouping.priority => ['${t.priority.code}'],
      StatsGrouping.task => [t.id],
    };
    for (final k in keys) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
  }
  return counts.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => b.$2.compareTo(a.$2));
}

// ------------------------------------------------------------------ achievement

/// Upper bounds of the 12 levels of the "pontuação de conquista".
const achievementLevels = [50, 100, 200, 400, 700, 1100, 1600, 2300, 3200, 4500, 6000];

/// "Minha pontuação de conquista": +1 per task created, +2 per task completed (+1 more
/// when on time), −1 per task overdue. Counted up to today 00:00, as TickTick recalculates it daily.
int achievementScore(Snapshot s, DateTime now) {
  final today = startOfDay(now);
  var score = 0;
  for (final t in _live(s)) {
    if (t.createdAt.toLocal().isBefore(today)) score += 1;
    final done = t.completedAt?.toLocal();
    if (t.status == TaskStatus.completed && done != null && done.isBefore(today)) score += _onTime(t) ? 3 : 2;
    if (t.status == TaskStatus.open && (t.daysToEnd(today) ?? 0) < 0) score -= 1;
  }
  return math.max(0, score);
}

/// Level 1 to 12 of a score, and the score where the next one starts (null at the top).
({int level, int? next}) achievementLevel(int score) {
  for (var i = 0; i < achievementLevels.length; i++) {
    if (score < achievementLevels[i]) return (level: i + 1, next: achievementLevels[i]);
  }
  return (level: achievementLevels.length + 1, next: null);
}

/// Days since the first list or task was created, today included ("N Dias").
int daysOfUse(Snapshot s, DateTime now) {
  DateTime? first;
  for (final at in [for (final l in s.lists) l.createdAt, for (final t in s.tasks) t.createdAt]) {
    if (first == null || at.isBefore(first)) first = at;
  }
  return first == null ? 1 : daysBetween(startOfDay(first.toLocal()), startOfDay(now)) + 1;
}

// ------------------------------------------------------------------ focus

List<FocusRecord> _focusBetween(List<FocusRecord> records, DateTime from, DateTime to) => [
  for (final r in records)
    if (r.deletedAt == null && _within(r.startedAt, from, to)) r,
];

int pomosBetween(List<FocusRecord> records, DateTime from, DateTime to) =>
    _focusBetween(records, from, to).where((r) => r.mode == FocusMode.pomo).length;

Duration focusBetween(List<FocusRecord> records, DateTime from, DateTime to) =>
    Duration(seconds: _focusBetween(records, from, to).fold(0, (sum, r) => sum + r.seconds));

/// Focus of the period by list, tag or task of the linked task (keys as in [completedBy]; '' = nothing
/// linked), longest first.
List<(String, Duration)> focusBy(Snapshot s, List<FocusRecord> records, DateTime from, DateTime to, StatsGrouping g) {
  final seconds = <String, int>{};
  for (final r in _focusBetween(records, from, to)) {
    final task = r.taskId == null ? null : s.taskById[r.taskId];
    // A habit link only groups by task (its "habit:<id>" key); habits have no list, tag or priority.
    final keys = focusHabitId(r.taskId) != null
        ? [if (g == StatsGrouping.task) r.taskId! else '']
        : task == null
        ? ['']
        : switch (g) {
            StatsGrouping.list => [task.listId],
            StatsGrouping.tag => [for (final tag in s.tagsOf(task.id)) tag.id].nonEmptyOr(''),
            StatsGrouping.priority => ['${task.priority.code}'],
            StatsGrouping.task => [task.id],
          };
    for (final k in keys) {
      seconds[k] = (seconds[k] ?? 0) + r.seconds;
    }
  }
  return seconds.entries.map((e) => (e.key, Duration(seconds: e.value))).toList()..sort((a, b) => b.$2.compareTo(a.$2));
}

extension on List<String> {
  List<String> nonEmptyOr(String fallback) => isEmpty ? [fallback] : this;
}

/// Minutes of focus in each hour (0-23) of each day from [from], [days] days: the "Tempo mais
/// concentrado" heatmap and the week's "Linha do Tempo". Sessions crossing an hour are split.
List<List<double>> focusByHour(List<FocusRecord> records, DateTime from, int days) {
  final grid = List.generate(days, (_) => List<double>.filled(24, 0));
  final to = DateTime(from.year, from.month, from.day + days);
  for (final r in records) {
    if (r.deletedAt != null) continue;
    var at = r.startedAt.toLocal();
    final end = r.endedAt.toLocal();
    while (at.isBefore(end)) {
      final hourEnd = DateTime(at.year, at.month, at.day, at.hour + 1);
      final stop = hourEnd.isBefore(end) ? hourEnd : end;
      if (!at.isBefore(from) && at.isBefore(to)) {
        grid[daysBetween(from, startOfDay(at))][at.hour] += stop.difference(at).inSeconds / 60;
      }
      at = stop;
    }
  }
  return grid;
}

/// Level of a day of the annual grid: 0m · 0-1h · 1h-3h · 3h-5h · >5h → 0 to 4.
int focusDayLevel(Duration d) => switch (d.inMinutes) {
  0 => 0,
  < 60 => 1,
  < 180 => 2,
  < 300 => 3,
  _ => 4,
};

// ------------------------------------------------------------------ medals

/// Medals of the statistics that make sense for one person on one device. VIP (months
/// of subscription) and Coração caloroso (accepted invitations) have no counterpart here.
enum MedalKind { perseverance, getThingsDone, mindfulness, selfDiscipline }

/// Thresholds of each level; the spec gives the ranges (days of use 3→1000, tasks 5→5000), the steps
/// in between are ours.
const medalLevels = <MedalKind, List<int>>{
  MedalKind.perseverance: [3, 7, 15, 30, 60, 100, 200, 365, 500, 1000],
  MedalKind.getThingsDone: [5, 20, 50, 100, 200, 500, 1000, 2000, 5000],
  MedalKind.mindfulness: [25, 100, 500, 1000, 3000, 6000, 10000],
  MedalKind.selfDiscipline: [5, 20, 50, 100, 300, 500, 1000],
};

/// A medal: what was reached ([value]), the level (0 = locked) and the next threshold (null at the top).
class Medal {
  const Medal(this.kind, this.value, this.level, this.next);

  final MedalKind kind;
  final int value;
  final int level;
  final int? next;
}

Medal _medal(MedalKind kind, int value) {
  final levels = medalLevels[kind]!;
  final level = levels.where((l) => value >= l).length;
  return Medal(kind, value, level, level < levels.length ? levels[level] : null);
}

/// The four medals: days of use, completed tasks (at most 50 a day count, as in TickTick), minutes of
/// focus and habit days done.
List<Medal> medals(Snapshot s, List<FocusRecord> records, DateTime now) {
  final perDay = <DateTime, int>{};
  for (final t in _live(s)) {
    final done = t.completedAt?.toLocal();
    if (t.status == TaskStatus.completed && done != null) perDay[startOfDay(done)] = (perDay[startOfDay(done)] ?? 0) + 1;
  }
  final tasks = perDay.values.fold(0, (sum, n) => sum + math.min(n, 50));
  final minutes = records.where((r) => r.deletedAt == null).fold(0, (sum, r) => sum + r.seconds) ~/ 60;
  var checkins = 0;
  for (final h in s.habits.where((h) => h.deletedAt == null)) {
    checkins += s.checkinsOf(h.id).where((c) => c.deletedAt == null && habitGoalMet(h, c.value)).length;
  }
  return [
    _medal(MedalKind.perseverance, daysOfUse(s, now)),
    _medal(MedalKind.getThingsDone, tasks),
    _medal(MedalKind.mindfulness, minutes),
    _medal(MedalKind.selfDiscipline, checkins),
  ];
}
