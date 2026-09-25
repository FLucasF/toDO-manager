import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';
import 'recurrence.dart';

/// Where the countdown's day is relative to today.
enum CountdownPhase { future, today, past }

/// What a countdown card shows: the day it counts to (the next occurrence when it
/// repeats), the big number and, for birthdays with "Mostrar idade", the age on that day.
class CountdownStatus {
  const CountdownStatus({required this.target, required this.days, required this.phase, this.age});

  final DateTime target;
  final int days;
  final CountdownPhase phase;
  final int? age;
}

/// The countdown's calendar date (stored at UTC midnight) as a local date.
DateTime countdownDate(Countdown c) => DateTime(c.date.year, c.date.month, c.date.day);

/// [countUp] overrides the countdown's "Modo de Contagem" (a click on the card flips it).
CountdownStatus countdownStatus(Countdown c, DateTime now, {bool? countUp}) {
  final today = startOfDay(now);
  final date = countdownDate(c);
  // "Cronômetro": days since the date itself, once it has passed.
  if ((countUp ?? c.countUp) && date.isBefore(today)) {
    final since = daysBetween(date, today) + (c.countMode == CountMode.plusOne ? 1 : 0);
    final age = c.type == CountdownType.birthday && c.showAge && !c.ignoreYear ? _yearsBetween(date, today) : null;
    return CountdownStatus(target: date, days: since, phase: CountdownPhase.past, age: age);
  }
  final rule = c.repeatRule;
  final target = rule == null ? date : (occurrenceOnOrAfter(rule: rule, start: date, day: today) ?? date);
  final diff = daysBetween(today, target);
  final phase = diff > 0 ? CountdownPhase.future : (diff == 0 ? CountdownPhase.today : CountdownPhase.past);
  // Counting up: "Padrão +1 dia" makes the date itself day 1.
  final days = switch (phase) {
    CountdownPhase.future => diff,
    CountdownPhase.today => c.countMode == CountMode.plusOne ? 1 : 0,
    CountdownPhase.past => -diff + (c.countMode == CountMode.plusOne ? 1 : 0),
  };
  final age = c.type == CountdownType.birthday && c.showAge && !c.ignoreYear ? target.year - date.year : null;
  return CountdownStatus(target: target, days: days, phase: phase, age: age);
}

int _yearsBetween(DateTime from, DateTime to) =>
    to.year - from.year - ((to.month < from.month || (to.month == from.month && to.day < from.day)) ? 1 : 0);

/// Cards in order: the pinned one first, then by the nearest date — the days still
/// ahead, soonest first, then the ones already past, most recent first.
List<Countdown> sortCountdowns(Iterable<Countdown> countdowns, DateTime now) {
  int rank(Countdown c) {
    final status = countdownStatus(c, now, countUp: false);
    return status.phase == CountdownPhase.past ? 1000000 + status.days : status.days;
  }

  return countdowns.toList()..sort((a, b) {
    final pin = (b.pinnedAt != null ? 1 : 0).compareTo(a.pinnedAt != null ? 1 : 0);
    if (pin != 0) return pin;
    final byDate = rank(a).compareTo(rank(b));
    return byDate != 0 ? byDate : a.sortOrder.compareTo(b.sortOrder);
  });
}

/// Whether the countdown shows in the smart list of [day] ("Mostrar na Lista Inteligente").
bool countdownShowsOn(Countdown c, DateTime day, DateTime now) {
  if (c.deletedAt != null || c.archivedAt != null) return false;
  // The next occurrence, even when the card counts up.
  final target = countdownStatus(c, day, countUp: false).target;
  final ahead = daysBetween(startOfDay(day), target);
  return switch (c.visibility) {
    CountdownVisibility.never => false,
    CountdownVisibility.always => true,
    CountdownVisibility.onTheDay => ahead == 0,
    CountdownVisibility.threeDaysBefore => ahead >= 0 && ahead <= 3,
    CountdownVisibility.sevenDaysBefore => ahead >= 0 && ahead <= 7,
  };
}
