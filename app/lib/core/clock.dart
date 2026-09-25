/// Source of the current time. Tests inject a fixed time to control "today", "tomorrow" and "overdue".
abstract interface class Clock {
  /// Current local time.
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

final class FixedClock implements Clock {
  FixedClock(this.time);

  DateTime time;

  @override
  DateTime now() => time;
}

/// Local midnight of [date]'s day.
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Number of calendar days (local) from [from] to [to]; negative when [to] is earlier.
int daysBetween(DateTime from, DateTime to) {
  // Noon avoids off-by-one-hour errors around daylight saving changes.
  final a = DateTime.utc(from.year, from.month, from.day, 12);
  final b = DateTime.utc(to.year, to.month, to.day, 12);
  return b.difference(a).inDays;
}

/// Settings → Data e hora. The app copies them from the preferences on every build, so
/// the pure date functions below follow the user's choice; tests keep the defaults.
abstract final class DateConventions {
  /// First day of the week: [DateTime.sunday] (default), [DateTime.monday] or [DateTime.saturday].
  static int firstWeekday = DateTime.sunday;

  /// "Formato da hora": 24h (13:00) or 12h (1:00 PM).
  static bool use24h = true;

  /// "Mostrar números da semana" in the calendar.
  static bool weekNumbers = false;

  /// "Formato de data": 31/12/2026, 12/31/2026 or 2026/12/31.
  static DateOrder dateOrder = DateOrder.dayMonthYear;
}

enum DateOrder { dayMonthYear, monthDayYear, yearMonthDay }

/// Local midnight of the first day of [date]'s week.
DateTime startOfWeek(DateTime date) => DateTime(date.year, date.month, date.day - (date.weekday - DateConventions.firstWeekday + 7) % 7);

/// The seven weekday numbers (1 = Monday … 7 = Sunday) in the order the week starts.
List<int> weekdayOrder() => [for (var i = 0; i < 7; i++) (DateConventions.firstWeekday - 1 + i) % 7 + 1];

/// ISO 8601 week number of [date] (the "W39" of the calendar).
int isoWeekNumber(DateTime date) {
  final thursday = DateTime(date.year, date.month, date.day + DateTime.thursday - date.weekday);
  return daysBetween(DateTime(thursday.year), thursday) ~/ 7 + 1;
}
