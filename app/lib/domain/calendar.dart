import 'dart:convert';

import '../core/clock.dart';
import '../data/db/database.dart';
import 'countdown.dart';
import 'enums.dart';
import 'focus.dart';
import 'habits.dart';
import 'recurrence.dart';
import 'snapshot.dart';
import 'subscriptions.dart';
import 'task_dates.dart';

/// Calendar modes and their route codes (`#c/all/calendar/{mode}`).
enum CalendarMode {
  day('d'),
  week('w'),
  month('m'),
  year('y'),
  agenda('a'),
  multiDay('md'),
  multiWeek('mw');

  const CalendarMode(this.route);
  final String route;

  static CalendarMode fromRoute(String? route) => values.where((m) => m.route == route).firstOrNull ?? month;

  /// Modes drawn as a timeline of hours (the others are grids or lists).
  bool get isTimeline => this == day || this == week || this == multiDay;
}

/// "Cor por" of the view options.
enum CalendarColorBy { list, tag, priority }

/// "Opções de visualização" of the calendar and the list filter.
class CalendarOptions {
  const CalendarOptions({
    this.showCompleted = true,
    this.showChecklistItems = false,
    this.showRepeats = true,
    this.showHabits = true,
    this.showFocus = false,
    this.showCountdowns = true,
    this.showFinance = true,
    this.colorBy = CalendarColorBy.list,
    this.multiDays = 3,
    this.multiWeeks = 5,
    this.listIds = const {},
    this.classicStyle = false,
    this.showIcons = false,
    this.timeZones = const [],
    this.hiddenBefore = 7,
    this.hiddenAfter = 21,
    this.showWeekends = true,
    this.dimPast = false,
    this.shortAs30 = true,
  });

  final bool showCompleted;
  final bool showChecklistItems;

  /// "Mostrar ciclos futuros": the next occurrences of repeating tasks.
  final bool showRepeats;
  final bool showHabits;
  final bool showFocus;
  final bool showCountdowns;

  /// Finanças: recurring bills, card invoices and loans on their due days.
  final bool showFinance;
  final CalendarColorBy colorBy;

  /// Multi-Dia: 1 to 14 days; Multi-Semana: 1 to 6 weeks.
  final int multiDays;
  final int multiWeeks;

  /// Lists shown; empty = all.
  final Set<String> listIds;

  /// "Estilo": Clássico fills the entries with their color; Moderno (the default) tints them.
  final bool classicStyle;

  /// "Mostrar ícones": a checkbox, habit, countdown, focus or event icon before each title.
  final bool showIcons;

  /// "Fusos adicionais": IANA ids shown as extra hour columns of the timeline, at most [maxTimeZones].
  final List<String> timeZones;

  static const maxTimeZones = 4;

  /// The timeline hides the hours before [hiddenBefore] and from [hiddenAfter].
  final int hiddenBefore;
  final int hiddenAfter;

  /// "Mostrar fins de semana" (Google Calendar): off, the week's timeline leaves Saturday and Sunday out.
  final bool showWeekends;

  /// "Reduzir o brilho de eventos passados" (Google Calendar): entries that already ended fade.
  final bool dimPast;

  /// "Eventos curtos com o tamanho de 30 minutos" (Google Calendar): shorter blocks are drawn as tall
  /// as half an hour, so their title fits.
  final bool shortAs30;

  CalendarOptions copyWith({
    bool? showCompleted,
    bool? showChecklistItems,
    bool? showRepeats,
    bool? showHabits,
    bool? showFocus,
    bool? showCountdowns,
    bool? showFinance,
    CalendarColorBy? colorBy,
    int? multiDays,
    int? multiWeeks,
    Set<String>? listIds,
    bool? classicStyle,
    bool? showIcons,
    List<String>? timeZones,
    int? hiddenBefore,
    int? hiddenAfter,
    bool? showWeekends,
    bool? dimPast,
    bool? shortAs30,
  }) => CalendarOptions(
    showCompleted: showCompleted ?? this.showCompleted,
    showChecklistItems: showChecklistItems ?? this.showChecklistItems,
    showRepeats: showRepeats ?? this.showRepeats,
    showHabits: showHabits ?? this.showHabits,
    showFocus: showFocus ?? this.showFocus,
    showCountdowns: showCountdowns ?? this.showCountdowns,
    showFinance: showFinance ?? this.showFinance,
    colorBy: colorBy ?? this.colorBy,
    multiDays: (multiDays ?? this.multiDays).clamp(1, 14),
    multiWeeks: (multiWeeks ?? this.multiWeeks).clamp(1, 6),
    listIds: listIds ?? this.listIds,
    classicStyle: classicStyle ?? this.classicStyle,
    showIcons: showIcons ?? this.showIcons,
    timeZones: timeZones == null ? this.timeZones : timeZones.take(maxTimeZones).toList(),
    hiddenBefore: (hiddenBefore ?? this.hiddenBefore).clamp(0, 12),
    hiddenAfter: (hiddenAfter ?? this.hiddenAfter).clamp(12, 24),
    showWeekends: showWeekends ?? this.showWeekends,
    dimPast: dimPast ?? this.dimPast,
    shortAs30: shortAs30 ?? this.shortAs30,
  );

  Map<String, Object> toJson() => {
    'completed': showCompleted,
    'checklist': showChecklistItems,
    'repeats': showRepeats,
    'habits': showHabits,
    'focus': showFocus,
    'countdowns': showCountdowns,
    'finance': showFinance,
    'colorBy': colorBy.name,
    'multiDays': multiDays,
    'multiWeeks': multiWeeks,
    'lists': listIds.toList(),
    'classic': classicStyle,
    'icons': showIcons,
    'zones': timeZones,
    'hideBefore': hiddenBefore,
    'hideAfter': hiddenAfter,
    'weekends': showWeekends,
    'dimPast': dimPast,
    'short30': shortAs30,
  };

  static CalendarOptions fromJson(Object? json) {
    const d = CalendarOptions();
    if (json is! Map<String, Object?>) return d;
    bool flag(String key, bool fallback) => json[key] is bool ? json[key]! as bool : fallback;
    int number(String key, int fallback) => json[key] is int ? json[key]! as int : fallback;
    final lists = json['lists'];
    final zones = json['zones'];
    return d.copyWith(
      showCompleted: flag('completed', d.showCompleted),
      showChecklistItems: flag('checklist', d.showChecklistItems),
      showRepeats: flag('repeats', d.showRepeats),
      showHabits: flag('habits', d.showHabits),
      showFocus: flag('focus', d.showFocus),
      showCountdowns: flag('countdowns', d.showCountdowns),
      showFinance: flag('finance', d.showFinance),
      colorBy: CalendarColorBy.values.where((c) => c.name == json['colorBy']).firstOrNull,
      multiDays: number('multiDays', d.multiDays),
      multiWeeks: number('multiWeeks', d.multiWeeks),
      listIds: lists is List<Object?>
          ? {
              for (final l in lists)
                if (l is String) l,
            }
          : null,
      classicStyle: flag('classic', d.classicStyle),
      showIcons: flag('icons', d.showIcons),
      timeZones: zones is List<Object?> ? zones.whereType<String>().toList() : null,
      hiddenBefore: number('hideBefore', d.hiddenBefore),
      hiddenAfter: number('hideAfter', d.hiddenAfter),
      showWeekends: json['weekends'] != false,
      dimPast: json['dimPast'] == true,
      shortAs30: json['short30'] != false,
    );
  }

  String encode() => jsonEncode(toJson());
}

/// First day of the week of [day] ("Dia de início da semana", Sunday by default).
DateTime weekStartOf(DateTime day) => startOfWeek(day);

/// First day and number of days a mode shows around [anchor].
({DateTime from, int days}) calendarPeriod(CalendarMode mode, DateTime anchor, CalendarOptions o) {
  final day = startOfDay(anchor);
  switch (mode) {
    case CalendarMode.day:
      return (from: day, days: 1);
    case CalendarMode.week:
      return (from: weekStartOf(day), days: 7);
    case CalendarMode.multiDay:
      return (from: day, days: o.multiDays);
    case CalendarMode.multiWeek:
      return (from: weekStartOf(day), days: 7 * o.multiWeeks);
    case CalendarMode.month:
      final first = DateTime(day.year, day.month);
      final start = weekStartOf(first);
      final last = DateTime(day.year, day.month + 1, 0);
      final weeks = (daysBetween(start, last) ~/ 7) + 1;
      return (from: start, days: weeks * 7);
    case CalendarMode.year:
      return (from: DateTime(day.year), days: daysBetween(DateTime(day.year), DateTime(day.year + 1)));
    case CalendarMode.agenda:
      return (from: day, days: 31);
  }
}

/// The anchor after one step of ‹ / › (dir = -1 / 1).
DateTime calendarStep(CalendarMode mode, DateTime anchor, int dir, CalendarOptions o) {
  final day = startOfDay(anchor);
  DateTime plusDays(int n) => DateTime(day.year, day.month, day.day + n);
  return switch (mode) {
    CalendarMode.day => plusDays(dir),
    CalendarMode.week => plusDays(7 * dir),
    CalendarMode.multiDay => plusDays(o.multiDays * dir),
    CalendarMode.multiWeek => plusDays(7 * o.multiWeeks * dir),
    // The 1st keeps a month step from skipping February.
    CalendarMode.month || CalendarMode.agenda => DateTime(day.year, day.month + dir),
    CalendarMode.year => DateTime(day.year + dir),
  };
}

enum CalendarEntryKind { task, checklistItem, habit, countdown, focus, event, finance }

/// Something drawn on the calendar. All-day entries span local midnights [start]..[end] (end day
/// included); timed ones run from [start] to [end].
class CalendarEntry {
  const CalendarEntry({
    required this.kind,
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.isAllDay,
    this.task,
    this.isOccurrence = false,
    this.isDone = false,
  });

  final CalendarEntryKind kind;

  /// The task, item, habit, countdown or focus record id.
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;

  /// The task (for items, the task that holds them).
  final Task? task;

  /// A future cycle of a repeating task ("Mostrar ciclos futuros"); it cannot be dragged.
  final bool isOccurrence;
  final bool isDone;

  /// Whether the entry can be dragged or resized.
  bool get isEditable => kind == CalendarEntryKind.task && !isOccurrence;

  /// First and last local day the entry touches.
  DateTime get firstDay => startOfDay(start);
  DateTime get lastDay {
    if (isAllDay) return startOfDay(end);
    // A timed entry ending exactly at midnight does not touch that day.
    final last = end.isAfter(start) && end == startOfDay(end) ? end.subtract(const Duration(minutes: 1)) : end;
    return startOfDay(last);
  }

  bool touches(DateTime day) => !day.isBefore(firstDay) && !day.isAfter(lastDay);
}

/// Length a timed task without a duration takes on the timeline.
const calendarDefaultBlock = Duration(minutes: 30);

/// Entries of [s] between [from] (inclusive) and [to] (exclusive), days as local midnights.
List<CalendarEntry> calendarEntries(
  Snapshot s,
  DateTime from,
  DateTime to,
  CalendarOptions o, {
  required DateTime now,
  List<FocusRecord> focusRecords = const [],
  List<SubscribedEvent> events = const [],
}) {
  final entries = <CalendarEntry>[];
  bool overlaps(DateTime first, DateTime last) => !last.isBefore(from) && first.isBefore(to);
  bool listShown(String listId) {
    final list = s.listById[listId];
    if (list == null || list.deletedAt != null || list.archivedAt != null) return false;
    return o.listIds.isEmpty || o.listIds.contains(listId);
  }

  for (final t in s.tasks) {
    if (t.deletedAt != null || t.dueDate == null || !listShown(t.listId)) continue;
    final done = t.status != TaskStatus.open;
    if (done && !o.showCompleted) continue;
    final start = t.startLocal!, end = t.endLocal!;
    final shownEnd = !t.isAllDay && !end.isAfter(start) ? start.add(calendarDefaultBlock) : end;
    final entry = CalendarEntry(
      kind: CalendarEntryKind.task,
      id: t.id,
      title: t.title,
      start: start,
      end: shownEnd,
      isAllDay: t.isAllDay,
      task: t,
      isDone: done,
    );
    if (overlaps(entry.firstDay, entry.lastDay)) entries.add(entry);

    final rule = t.repeatRule;
    if (o.showRepeats && rule != null && !done) {
      final length = shownEnd.difference(start);
      for (final at in occurrencesBetween(rule: rule, start: start, from: from.subtract(length), to: to)) {
        if (!at.isAfter(start)) continue;
        final occurrence = CalendarEntry(
          kind: CalendarEntryKind.task,
          id: t.id,
          title: t.title,
          start: at,
          end: t.isAllDay ? DateTime(at.year, at.month, at.day + daysBetween(start, end)) : at.add(length),
          isAllDay: t.isAllDay,
          task: t,
          isOccurrence: true,
        );
        if (overlaps(occurrence.firstDay, occurrence.lastDay)) entries.add(occurrence);
      }
    }
  }

  if (o.showChecklistItems) {
    for (final item in s.checklistItems) {
      final due = item.dueDate?.toLocal();
      final task = s.taskById[item.taskId];
      if (due == null || item.deletedAt != null || task == null || task.deletedAt != null || !listShown(task.listId)) continue;
      if (item.isCompleted && !o.showCompleted) continue;
      final start = item.isAllDay ? startOfDay(due) : due;
      if (!overlaps(startOfDay(start), startOfDay(start))) continue;
      entries.add(
        CalendarEntry(
          kind: CalendarEntryKind.checklistItem,
          id: item.id,
          title: item.title,
          start: start,
          end: item.isAllDay ? start : start.add(calendarDefaultBlock),
          isAllDay: item.isAllDay,
          task: task,
          isDone: item.isCompleted,
        ),
      );
    }
  }

  if (o.showHabits) {
    // "Hábitos com lembrete de hora aparecem no calendário".
    for (final h in s.habits) {
      if (h.deletedAt != null || h.archivedAt != null || h.reminders.isEmpty) continue;
      final times = [
        for (final r in h.reminders.split(','))
          if (RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(r.trim()) case final m?) (int.parse(m.group(1)!), int.parse(m.group(2)!)),
      ];
      for (var day = from; day.isBefore(to); day = DateTime(day.year, day.month, day.day + 1)) {
        if (!habitIsDue(h, day)) continue;
        final checkin = s.checkinsOf(h.id).where((c) => habitDay(c.day) == day).firstOrNull;
        final done = checkin != null && habitGoalMet(h, checkin.value);
        for (final (hour, minute) in times) {
          final at = DateTime(day.year, day.month, day.day, hour, minute);
          entries.add(
            CalendarEntry(
              kind: CalendarEntryKind.habit,
              id: h.id,
              title: h.name,
              start: at,
              end: at.add(calendarDefaultBlock),
              isAllDay: false,
              isDone: done,
            ),
          );
        }
      }
    }
  }

  if (o.showCountdowns) {
    for (final c in s.countdowns) {
      if (c.deletedAt != null || c.archivedAt != null) continue;
      final date = countdownDate(c);
      final rule = c.repeatRule;
      final days = rule == null ? [date] : occurrencesBetween(rule: rule, start: date, from: from, to: to);
      for (final d in days) {
        final day = startOfDay(d);
        if (day.isBefore(from) || !day.isBefore(to)) continue;
        entries.add(CalendarEntry(kind: CalendarEntryKind.countdown, id: c.id, title: c.name, start: day, end: day, isAllDay: true));
      }
    }
  }

  if (o.showFocus) {
    for (final r in focusRecords) {
      final start = r.startedAt.toLocal(), end = r.endedAt.toLocal();
      if (r.deletedAt != null || !overlaps(startOfDay(start), startOfDay(end))) continue;
      final task = r.taskId == null ? null : s.taskById[r.taskId];
      final habitId = focusHabitId(r.taskId);
      final habit = habitId == null ? null : s.habits.where((h) => h.id == habitId).firstOrNull;
      entries.add(
        CalendarEntry(
          kind: CalendarEntryKind.focus,
          id: r.id,
          title: task?.title ?? habit?.name ?? '',
          start: start,
          end: end.isAfter(start) ? end : start.add(const Duration(minutes: 1)),
          isAllDay: false,
          task: task,
          isDone: true,
        ),
      );
    }
  }

  // Events of the subscribed calendars; their id is the calendar's.
  for (final e in events) {
    entries.add(CalendarEntry(kind: CalendarEntryKind.event, id: e.calendarId, title: e.title, start: e.start, end: e.end, isAllDay: e.isAllDay));
  }

  entries.sort(compareCalendarEntries);
  return entries;
}

/// Earlier first; on the same start, longer first, then by title.
int compareCalendarEntries(CalendarEntry a, CalendarEntry b) {
  final byStart = a.start.compareTo(b.start);
  if (byStart != 0) return byStart;
  final byLength = b.end.difference(b.start).compareTo(a.end.difference(a.start));
  if (byLength != 0) return byLength;
  return a.title.compareTo(b.title);
}

/// Where an entry sits on a day's timeline: column [column] of [columns] side-by-side columns.
class TimelineSlot {
  const TimelineSlot(this.entry, this.column, this.columns);

  final CalendarEntry entry;
  final int column;
  final int columns;
}

/// Lays timed entries of one day out in columns, so overlapping ones sit side by side. Entries that
/// overlap (directly or through others) share the same number of columns.
List<TimelineSlot> layoutTimeline(List<CalendarEntry> timed) {
  final sorted = [...timed]..sort(compareCalendarEntries);
  final slots = <TimelineSlot>[];
  var cluster = <(CalendarEntry, int)>[];
  var columnEnds = <DateTime>[];
  DateTime? clusterEnd;

  void flush() {
    for (final (e, c) in cluster) {
      slots.add(TimelineSlot(e, c, columnEnds.length));
    }
    cluster = [];
    columnEnds = [];
    clusterEnd = null;
  }

  for (final e in sorted) {
    if (clusterEnd != null && !e.start.isBefore(clusterEnd!)) flush();
    var column = columnEnds.indexWhere((end) => !e.start.isBefore(end));
    if (column == -1) {
      column = columnEnds.length;
      columnEnds.add(e.end);
    } else {
      columnEnds[column] = e.end;
    }
    cluster.add((e, column));
    if (clusterEnd == null || e.end.isAfter(clusterEnd!)) clusterEnd = e.end;
  }
  flush();
  return slots;
}

/// A bar of a row of days (a month week or the "Dia inteiro" band): columns [first]..[last] of the
/// row, on lane [lane].
class SpanSlot {
  const SpanSlot(this.entry, this.first, this.last, this.lane);

  final CalendarEntry entry;
  final int first;
  final int last;
  final int lane;

  /// Whether the entry goes on before / after the row.
  bool continuesBefore(DateTime rowStart) => entry.firstDay.isBefore(rowStart);
  bool continuesAfter(DateTime rowStart, int days) => !entry.lastDay.isBefore(DateTime(rowStart.year, rowStart.month, rowStart.day + days));
}

/// Lays the entries touching the [days] days from [rowStart] out in lanes: longer and earlier
/// first, each on the first lane free for all its days.
List<SpanSlot> layoutSpans(List<CalendarEntry> entries, DateTime rowStart, int days) {
  final rowEnd = DateTime(rowStart.year, rowStart.month, rowStart.day + days - 1);
  final inRow = entries.where((e) => !e.lastDay.isBefore(rowStart) && !e.firstDay.isAfter(rowEnd)).toList()
    ..sort((a, b) {
      final byFirst = a.firstDay.compareTo(b.firstDay);
      if (byFirst != 0) return byFirst;
      final byLength = daysBetween(b.firstDay, b.lastDay).compareTo(daysBetween(a.firstDay, a.lastDay));
      if (byLength != 0) return byLength;
      // All-day entries before timed ones, then by time.
      if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
      return compareCalendarEntries(a, b);
    });
  final lanes = <List<bool>>[];
  final slots = <SpanSlot>[];
  for (final e in inRow) {
    final first = e.firstDay.isBefore(rowStart) ? 0 : daysBetween(rowStart, e.firstDay);
    final last = e.lastDay.isAfter(rowEnd) ? days - 1 : daysBetween(rowStart, e.lastDay);
    var lane = lanes.indexWhere((used) => used.sublist(first, last + 1).every((u) => !u));
    if (lane == -1) {
      lane = lanes.length;
      lanes.add(List.filled(days, false));
    }
    for (var i = first; i <= last; i++) {
      lanes[lane][i] = true;
    }
    slots.add(SpanSlot(e, first, last, lane));
  }
  return slots;
}

/// New dates of a task dragged to another place. All-day tasks keep their number of days; timed
/// ones keep their length. [day] is the drop day; [time] the drop time on a timeline (null = the
/// "Dia inteiro" band or a month cell).
({DateTime start, DateTime due, bool isAllDay}) movedDates(Task t, DateTime day, {DateTime? time}) {
  final start = t.startLocal!, end = t.endLocal!;
  if (time != null) {
    // Onto the timeline: keeps a timed task's length; an all-day task gets the time.
    final length = t.isAllDay ? Duration.zero : end.difference(start);
    return (start: time, due: time.add(length), isAllDay: false);
  }
  if (t.isAllDay) {
    final length = daysBetween(start, end);
    return (start: day, due: DateTime(day.year, day.month, day.day + length), isAllDay: true);
  }
  // A timed task moved to another day keeps its time.
  final shift = daysBetween(startOfDay(start), day);
  DateTime shifted(DateTime d) => DateTime(d.year, d.month, d.day + shift, d.hour, d.minute);
  return (start: shifted(start), due: shifted(end), isAllDay: false);
}

/// Rounds [time] down to the [minutes] grid of the timeline.
DateTime snapTime(DateTime time, {int minutes = 15}) => DateTime(time.year, time.month, time.day, time.hour, time.minute - time.minute % minutes);

/// A task's dates with the start and/or the end moved by whole days (the timeline's bar and edges).
/// Times of day stay; the start never passes the end.
({DateTime start, DateTime due, bool isAllDay}) shiftedDates(Task t, {int startDays = 0, int endDays = 0}) {
  final start = t.startLocal!, end = t.endLocal!;
  DateTime plus(DateTime d, int n) => DateTime(d.year, d.month, d.day + n, d.hour, d.minute);
  var from = plus(start, startDays), to = plus(end, endDays);
  if (from.isAfter(to)) {
    if (startDays != 0 && endDays == 0) {
      from = to;
    } else {
      to = from;
    }
  }
  return (start: from, due: to, isAllDay: t.isAllDay);
}

/// Scales of the timeline view: width of one day in pixels.
enum TimelineScale {
  day(64),
  week(24),
  month(8);

  const TimelineScale(this.dayWidth);
  final double dayWidth;
}
