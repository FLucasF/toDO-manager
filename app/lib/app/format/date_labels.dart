import '../../core/clock.dart';
import '../../l10n/app_localizations.dart';

/// Date texts exactly as TickTick shows them (measured on the webapp on 2026-09-24).
class DateLabels {
  const DateLabels(this._t);

  final AppLocalizations _t;

  List<String> get _weekdays => [
    _t.weekdayMonday,
    _t.weekdayTuesday,
    _t.weekdayWednesday,
    _t.weekdayThursday,
    _t.weekdayFriday,
    _t.weekdaySaturday,
    _t.weekdaySunday,
  ];

  List<String> get _weekdaysShort => [
    _t.weekdayShortMonday,
    _t.weekdayShortTuesday,
    _t.weekdayShortWednesday,
    _t.weekdayShortThursday,
    _t.weekdayShortFriday,
    _t.weekdayShortSaturday,
    _t.weekdayShortSunday,
  ];

  List<String> get _months => [
    _t.monthJanuary,
    _t.monthFebruary,
    _t.monthMarch,
    _t.monthApril,
    _t.monthMay,
    _t.monthJune,
    _t.monthJuly,
    _t.monthAugust,
    _t.monthSeptember,
    _t.monthOctober,
    _t.monthNovember,
    _t.monthDecember,
  ];

  List<String> get _monthsShort => [
    _t.monthShortJanuary,
    _t.monthShortFebruary,
    _t.monthShortMarch,
    _t.monthShortApril,
    _t.monthShortMay,
    _t.monthShortJune,
    _t.monthShortJuly,
    _t.monthShortAugust,
    _t.monthShortSeptember,
    _t.monthShortOctober,
    _t.monthShortNovember,
    _t.monthShortDecember,
  ];

  String weekday(DateTime d) => _weekdays[d.weekday - 1];
  String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];
  String monthLong(DateTime d) => _months[d.month - 1];

  /// "Sexta-feira, 25 de setembro de 2026" (the hint of the calendar's "Hoje").
  String fullDate(DateTime d) => _t.dateFull(weekday(d), d.day, monthLong(d).toLowerCase(), d.year);
  String monthShort(DateTime d) => _monthsShort[d.month - 1];

  /// Calendar title: "Setembro 2026".
  String monthTitle(DateTime d) {
    final name = monthLong(d);
    return '${name[0].toUpperCase()}${name.substring(1)} ${d.year}';
  }

  /// "13:00", or "1:00 PM" with the 12-hour format (Settings → Data e hora).
  static String time(DateTime d) => DateConventions.use24h
      ? '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}'
      : '${d.hour % 12 == 0 ? 12 : d.hour % 12}:${_twoDigits(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';

  /// Group header for a day: "Quinta-feira, Hoje", "Sexta-feira, Amanhã", "Sábado, 26 setembro".
  String dayHeader(DateTime day, DateTime today) {
    final name = weekday(day);
    return switch (daysBetween(today, day)) {
      0 => '$name, ${_t.relativeToday}',
      1 => '$name, ${_t.relativeTomorrow}',
      -1 => '$name, ${_t.relativeYesterday}',
      _ => day.year == today.year ? '$name, ${day.day} ${_months[day.month - 1]}' : '$name, ${day.day} ${_months[day.month - 1]} ${day.year}',
    };
  }

  /// Short date on the right of a task row: "18:48" (today with a time), "Hoje", "Amanhã", "Ontem",
  /// "Sáb" (within the next 6 days), "26 set" (otherwise; with the year when it differs).
  String rowDate(DateTime date, {required bool isAllDay, required DateTime today}) {
    final days = daysBetween(today, date);
    if (days == 0) return isAllDay ? _t.relativeToday : time(date);
    if (days == 1) return isAllDay ? _t.relativeTomorrow : '${_t.relativeTomorrow}, ${time(date)}';
    if (days == -1) return _t.relativeYesterday;
    if (days > 1 && days < 7) return weekdayShort(date);
    return _dayMonth(date, today);
  }

  /// Date in the task detail header: "Hoje, 24 set, 18:48", "Amanhã, 25 set", "Sáb, 26 set".
  String detailDate(DateTime date, {required bool isAllDay, required DateTime today}) {
    final relative = switch (daysBetween(today, date)) {
      0 => _t.relativeToday,
      1 => _t.relativeTomorrow,
      -1 => _t.relativeYesterday,
      _ => weekdayShort(date),
    };
    final base = '$relative, ${_dayMonth(date, today)}';
    return isAllDay ? base : '$base, ${time(date)}';
  }

  /// Row date as a countdown ("Mostrar Data por: Contagem regressiva"): a time
  /// less than a day from [now] is relative ("4 M", "3 H"); otherwise "Hoje", "Amanhã", "Ontem",
  /// "em 3 dias", "há 2 dias".
  String rowCountdown(DateTime date, {required bool isAllDay, required DateTime today, DateTime? now}) {
    if (!isAllDay && now != null) {
      final minutes = date.difference(now).inMinutes.abs();
      if (minutes < 60) return _t.countdownMinutesShort(minutes);
      if (minutes < 24 * 60) return _t.countdownHoursShort(minutes ~/ 60);
    }
    final days = daysBetween(today, date);
    return switch (days) {
      0 => isAllDay ? _t.relativeToday : time(date),
      1 => _t.relativeTomorrow,
      -1 => _t.relativeYesterday,
      > 1 => _t.countdownInDays(days),
      _ => _t.countdownDaysAgo(-days),
    };
  }

  /// Row text of a task with a duration: "10:00-11:00" (today), "Amanhã, 10:00-11:00", "22 set, 09:00-12:00"
  /// (another day: the day and both times), "Hoje - Sáb", "25 set - 3 out".
  String rowRange(DateTime start, DateTime end, {required bool isAllDay, required DateTime today}) {
    final from = rowDate(start, isAllDay: isAllDay, today: today);
    if (daysBetween(start, end) == 0) {
      if (isAllDay) return from;
      final hours = '${time(start)}-${time(end)}';
      final day = daysBetween(today, start);
      if (day == 0) return hours;
      return '${day == 1 ? _t.relativeTomorrow : rowDate(start, isAllDay: true, today: today)}, $hours';
    }
    return '$from - ${rowDate(end, isAllDay: isAllDay, today: today)}';
  }

  /// Detail header text of a task with a duration: "Hoje, 25 set, 10:00 - 11:00", "Hoje, 25 set - Sáb, 27 set".
  String detailRange(DateTime start, DateTime end, {required bool isAllDay, required DateTime today}) {
    final from = detailDate(start, isAllDay: isAllDay, today: today);
    if (daysBetween(start, end) == 0) return isAllDay ? from : '$from - ${time(end)}';
    return '$from - ${detailDate(end, isAllDay: isAllDay, today: today)}';
  }

  String _dayMonth(DateTime d, DateTime today) {
    final short = '${d.day} ${_monthsShort[d.month - 1]}';
    return d.year == today.year ? short : '$short ${d.year}';
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// "25/09/2026", or as "Formato de data" says; [withYear] false leaves the year out.
  static String numeric(DateTime d, {bool withYear = true}) {
    final day = _twoDigits(d.day), month = _twoDigits(d.month);
    return switch ((DateConventions.dateOrder, withYear)) {
      (DateOrder.dayMonthYear, true) => '$day/$month/${d.year}',
      (DateOrder.dayMonthYear, false) => '$day/$month',
      (DateOrder.monthDayYear, true) => '$month/$day/${d.year}',
      (DateOrder.yearMonthDay, true) => '${d.year}/$month/$day',
      (DateOrder.monthDayYear || DateOrder.yearMonthDay, false) => '$month/$day',
    };
  }
}
