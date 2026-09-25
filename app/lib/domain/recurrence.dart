import 'package:rrule/rrule.dart';

/// Where the next occurrence of a repeating task is counted from.
enum RepeatFrom {
  dueDate('dueDate'),
  completion('completion');

  const RepeatFrom(this.code);
  final String code;

  static RepeatFrom fromCode(String? code) => values.where((v) => v.code == code).firstOrNull ?? RepeatFrom.dueDate;
}

/// Result of completing one occurrence: the next due date and the rule to keep (COUNT decremented).
class NextOccurrence {
  const NextOccurrence(this.dueDate, this.rule);

  /// Local date/time of the next occurrence.
  final DateTime dueDate;

  /// RRULE body (without the `RRULE:` prefix) to store for the next occurrence.
  final String rule;
}

/// Next occurrence after completing a repeating task, or null when the repetition has ended
/// ("Em 2 tempos" → "Em 1 tempo"; `UNTIL` = "Termina na data").
///
/// [rule] is the stored RRULE body, e.g. `FREQ=WEEKLY;INTERVAL=1;BYDAY=TH` or `FREQ=DAILY;COUNT=3`.
/// `COUNT` means the occurrences left, including the current one.
NextOccurrence? nextOccurrence({required String rule, required DateTime dueDate, required RepeatFrom from, required DateTime completedAt}) {
  final dates = specificDates(rule);
  if (dates != null) {
    final next = dates.where((d) => d.isAfter(DateTime(dueDate.year, dueDate.month, dueDate.day))).firstOrNull;
    return next == null ? null : NextOccurrence(DateTime(next.year, next.month, next.day, dueDate.hour, dueDate.minute), rule);
  }
  final skip = skipsWeekends(rule);
  final parsed = RecurrenceRule.fromString('RRULE:${_body(rule)}');
  final count = parsed.count;
  if (count != null && count <= 1) return null;

  // rrule works with "floating" times expressed as UTC.
  final base = from == RepeatFrom.completion
      ? DateTime.utc(completedAt.year, completedAt.month, completedAt.day, dueDate.hour, dueDate.minute)
      : _floating(dueDate);
  final open = parsed.copyWith(clearCount: true, clearUntil: true);
  final excluded = _excluded(rule);
  final found = open
      .getInstances(start: base, after: base)
      .take(1000)
      .map((d) => skip ? _weekday(d) : d)
      .where((d) => !excluded.contains(_dayKey(d)))
      .firstOrNull;
  if (found == null) return null;
  final next = found;
  final until = parsed.until;
  if (until != null && next.isAfter(until)) return null;

  final kept = count == null ? parsed : parsed.copyWith(count: count - 1);
  return NextOccurrence(
    DateTime(next.year, next.month, next.day, next.hour, next.minute),
    _withExclusions(withSkipWeekends(kept.toString().replaceFirst('RRULE:', ''), skip: skip), excluded),
  );
}

/// Upcoming occurrences (for highlighting in the date picker's calendar).
List<DateTime> upcomingOccurrences({required String rule, required DateTime from, int limit = 10}) {
  final dates = specificDates(rule);
  if (dates != null) {
    final day = DateTime(from.year, from.month, from.day);
    return [for (final d in dates.where((d) => !d.isBefore(day)).take(limit)) DateTime(d.year, d.month, d.day, from.hour, from.minute)];
  }
  final parsed = RecurrenceRule.fromString('RRULE:${_body(rule)}');
  final start = _floating(from);
  final excluded = _excluded(rule);
  return _shifted(rule, [
    for (final d in parsed.getInstances(start: start).take(limit + excluded.length)) DateTime(d.year, d.month, d.day, d.hour, d.minute),
  ]).where((d) => !excluded.contains(_dayKey(d))).take(limit).toList();
}

/// Occurrences of [rule] (its first one at [start]) from [from] (inclusive) to [to] (exclusive), at
/// most [limit]; the calendar's "Mostrar ciclos futuros".
List<DateTime> occurrencesBetween({required String rule, required DateTime start, required DateTime from, required DateTime to, int limit = 400}) {
  final dates = specificDates(rule);
  if (dates != null) {
    return [
      for (final d in dates)
        if (!d.isBefore(DateTime(from.year, from.month, from.day)) && d.isBefore(to)) DateTime(d.year, d.month, d.day, start.hour, start.minute),
    ];
  }
  if (!isValidRule(rule)) return const [];
  final parsed = RecurrenceRule.fromString('RRULE:${_body(rule)}');
  final after = from.isAfter(start) ? _floating(from) : null;
  final excluded = _excluded(rule);
  return _shifted(rule, [
    for (final d
        in parsed.getInstances(start: _floating(start), after: after, includeAfter: true).takeWhile((d) => d.isBefore(_floating(to))).take(limit))
      DateTime(d.year, d.month, d.day, d.hour, d.minute),
  ]).where((d) => !excluded.contains(_dayKey(d))).toList();
}

/// Whether [rule] parses as a valid RRULE body.
bool isValidRule(String rule) {
  if (rule.startsWith(_datesPrefix)) return specificDates(rule)?.isNotEmpty ?? false;
  // The rrule parser throws FormatException or RangeError depending on the input.
  try {
    RecurrenceRule.fromString('RRULE:${_body(rule)}');
    return true;
  } on Object {
    return false;
  }
}

/// "Pular finais de semana", kept with the rule as TickTick does.
const _skipWeekend = 'TT_SKIP=WEEKEND';

bool skipsWeekends(String rule) => rule.split(';').contains(_skipWeekend);

/// [rule] with or without "Pular finais de semana".
String withSkipWeekends(String rule, {required bool skip}) =>
    [...rule.split(';').where((p) => p.isNotEmpty && p != _skipWeekend), if (skip) _skipWeekend].join(';');

/// The RRULE the parser understands (without the extensions).
String _body(String rule) => rule.split(';').where((p) => p != _skipWeekend && !p.startsWith(_exdatePrefix)).join(';');

/// Occurrences taken out of the series ("Somente esta" in Google Calendar's "Excluir tarefa
/// repetida"), by the day they start: `TT_EXDATE=20261001,20261008`.
const _exdatePrefix = 'TT_EXDATE=';

String _dayKey(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

Set<String> _excluded(String rule) => {
  for (final p in rule.split(';'))
    if (p.startsWith(_exdatePrefix)) ...p.substring(_exdatePrefix.length).split(',').where((d) => d.length == 8),
};

String _withExclusions(String rule, Set<String> days) => [
  ...rule.split(';').where((p) => p.isNotEmpty && !p.startsWith(_exdatePrefix)),
  if (days.isNotEmpty) '$_exdatePrefix${(days.toList()..sort()).join(',')}',
].join(';');

/// [rule] without the occurrence that starts on [day]. A `DATES=` rule loses that date.
String excludingDay(String rule, DateTime day) {
  final dates = specificDates(rule);
  if (dates != null) return specificDatesRule(dates.where((d) => _dayKey(d) != _dayKey(day)));
  return _withExclusions(rule, {..._excluded(rule), _dayKey(day)});
}

/// [rule] ending on [lastDay] ("Esta e as seguintes" leaves the ones before): its COUNT or UNTIL is
/// replaced by an UNTIL at the end of that day.
String endingOn(String rule, DateTime lastDay) {
  final dates = specificDates(rule);
  if (dates != null) return specificDatesRule(dates.where((d) => !d.isAfter(DateTime(lastDay.year, lastDay.month, lastDay.day))));
  final kept = rule.split(';').where((p) => p.isNotEmpty && !p.startsWith('COUNT=') && !p.startsWith('UNTIL=')).join(';');
  return '$kept;UNTIL=${_dayKey(lastDay)}T235959Z';
}

/// The rule without its exceptions, to compare with the presets.
String withoutExclusions(String rule) => _withExclusions(rule, const {});

/// A Saturday or Sunday moves to the Monday after.
DateTime _weekday(DateTime d) => switch (d.weekday) {
  DateTime.saturday => d.add(const Duration(days: 2)),
  DateTime.sunday => d.add(const Duration(days: 1)),
  _ => d,
};

/// [dates] of [rule] with weekends moved to Monday (without repeating a day).
List<DateTime> _shifted(String rule, List<DateTime> dates) => skipsWeekends(rule) ? {for (final d in dates) _weekday(d)}.toList() : dates;

DateTime _floating(DateTime local) => DateTime.utc(local.year, local.month, local.day, local.hour, local.minute);

/// "Por datas específicas" cannot be written as an RRULE; it is stored as
/// `DATES=20260925,20261003` in the same column.
const _datesPrefix = 'DATES=';

String specificDatesRule(Iterable<DateTime> dates) {
  String two(int n) => n.toString().padLeft(2, '0');
  final days = {for (final d in dates) '${d.year}${two(d.month)}${two(d.day)}'}.toList()..sort();
  return '$_datesPrefix${days.join(',')}';
}

/// The dates of a `DATES=` rule in order, or null for an RRULE (or a malformed list).
List<DateTime>? specificDates(String rule) {
  if (!rule.startsWith(_datesPrefix)) return null;
  final dates = <DateTime>[];
  for (final part in rule.substring(_datesPrefix.length).split(',')) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(part);
    if (m == null) return null;
    dates.add(DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!)));
  }
  return dates..sort();
}

/// First occurrence of [rule] (starting at [start]) on or after [day], as a local date; null when the
/// rule has ended. Used by repeating countdowns.
DateTime? occurrenceOnOrAfter({required String rule, required DateTime start, required DateTime day}) {
  final dates = specificDates(rule);
  if (dates != null) return dates.where((d) => !d.isBefore(DateTime(day.year, day.month, day.day))).firstOrNull;
  final parsed = RecurrenceRule.fromString('RRULE:${_body(rule)}');
  final from = _floating(DateTime(day.year, day.month, day.day));
  final base = _floating(DateTime(start.year, start.month, start.day));
  if (!from.isAfter(base)) return DateTime(start.year, start.month, start.day);
  final excluded = _excluded(rule);
  final found = parsed
      .getInstances(start: base, after: from, includeAfter: true)
      .take(1000)
      .map((d) => skipsWeekends(rule) ? _weekday(d) : d)
      .where((d) => !excluded.contains(_dayKey(d)))
      .firstOrNull;
  if (found == null) return null;
  return DateTime(found.year, found.month, found.day);
}
