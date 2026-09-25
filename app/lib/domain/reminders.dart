/// Reminder triggers: ISO-8601 durations relative to the due date/time.
///
/// For all-day tasks the due date is local midnight, so the time of day is part of the trigger:
/// `PT9H` = on the day at 09:00, `-PT15H` = the day before at 09:00, `-P1DT15H` = two days before at 09:00.
library;

/// Presets of the date picker's "Lembrete" list.
abstract final class ReminderPresets {
  static const onTime = 'PT0S';
  static const fiveMinutesBefore = '-PT5M';
  static const thirtyMinutesBefore = '-PT30M';
  static const oneHourBefore = '-PT1H';
  static const oneDayBefore = '-P1D';

  static const timed = [onTime, fiveMinutesBefore, thirtyMinutesBefore, oneHourBefore, oneDayBefore];

  /// All-day presets: on the day and N days before, at 09:00.
  static const onTheDay = 'PT9H';
  static const oneDayBeforeAt9 = '-PT15H';
  static const twoDaysBeforeAt9 = '-P1DT15H';
  static const threeDaysBeforeAt9 = '-P2DT15H';
  static const oneWeekBeforeAt9 = '-P6DT15H';

  static const allDay = [onTheDay, oneDayBeforeAt9, twoDaysBeforeAt9, threeDaysBeforeAt9, oneWeekBeforeAt9];

  /// "No fim" of a task with a duration: at its end, not relative to the start.
  static const atEnd = 'END';

  /// "Lembrete constante" of this item: kept with the triggers, it is not a reminder
  /// itself; its notifications stay until dismissed.
  static const constant = 'CONSTANT';

  /// The triggers that fire (without [constant]).
  static Iterable<String> firing(Iterable<String> triggers) => triggers.where((t) => t != constant);
}

final _pattern = RegExp(r'^(-)?P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$');

/// Parses a trigger such as `-PT15M` or `-P1DT15H`. Throws [FormatException] for anything else.
Duration parseTrigger(String trigger) {
  final m = _pattern.firstMatch(trigger);
  if (m == null || trigger == 'P' || trigger == '-P' || trigger.endsWith('T')) throw FormatException('invalid reminder trigger: $trigger');
  int part(int i) => int.parse(m.group(i) ?? '0');
  final d = Duration(days: part(2), hours: part(3), minutes: part(4), seconds: part(5));
  return m.group(1) == null ? d : -d;
}

/// Formats a duration as a trigger (inverse of [parseTrigger]).
String formatTrigger(Duration d) {
  final negative = d.isNegative;
  var rest = d.abs();
  final days = rest.inDays;
  rest -= Duration(days: days);
  final hours = rest.inHours;
  rest -= Duration(hours: hours);
  final minutes = rest.inMinutes;
  final seconds = rest.inSeconds - minutes * 60;
  final time = [if (hours > 0) '${hours}H', if (minutes > 0) '${minutes}M', if (seconds > 0) '${seconds}S'].join();
  if (days == 0 && time.isEmpty) return 'PT0S';
  return '${negative ? '-' : ''}P${days > 0 ? '${days}D' : ''}${time.isEmpty ? '' : 'T$time'}';
}

/// When a reminder fires, in local time.
DateTime fireTime(DateTime localDue, String trigger) => localDue.add(parseTrigger(trigger));
