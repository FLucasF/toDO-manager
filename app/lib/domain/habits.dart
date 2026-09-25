import '../core/clock.dart';
import '../data/db/database.dart';
import 'enums.dart';

/// How a day of a habit looks (the dots of the list).
enum HabitDayState {
  /// Before the start date or not a day of the habit: hatched, "não necessário".
  notRequired,
  open,
  partial,
  done,
  skipped,
  failed,
}

/// Calendar day of a stored date (UTC midnight).
DateTime habitDay(DateTime stored) => DateTime(stored.year, stored.month, stored.day);

DateTime habitStart(Habit h) => habitDay(h.startDate);

Set<int> habitWeekdays(Habit h) => {for (final p in h.weekdays.split(',')) ?int.tryParse(p)};

/// Whether the habit asks for a check-in on [day]. "Semanal" (N times a week) accepts any day.
bool habitIsDue(Habit h, DateTime day) {
  final d = startOfDay(day);
  if (d.isBefore(habitStart(h))) return false;
  final target = h.targetDays;
  if (target != null && daysBetween(habitStart(h), d) >= target) return false;
  return switch (h.frequency) {
    HabitFrequency.daily => habitWeekdays(h).isEmpty || habitWeekdays(h).contains(d.weekday),
    HabitFrequency.weekly => true,
    HabitFrequency.interval => daysBetween(habitStart(h), d) % (h.everyDays < 1 ? 1 : h.everyDays) == 0,
  };
}

/// Whether a check-in value meets the day's goal.
bool habitGoalMet(Habit h, double value) => h.goal == HabitGoal.checkIn ? value > 0 : value >= h.goalAmount;

HabitDayState habitDayState(Habit h, HabitCheckin? c, DateTime day) {
  if (c?.mark == HabitMark.skipped) return HabitDayState.skipped;
  if (c?.mark == HabitMark.failed) return HabitDayState.failed;
  final value = c?.value ?? 0;
  if (value > 0 && habitGoalMet(h, value)) return HabitDayState.done;
  if (!habitIsDue(h, day)) return HabitDayState.notRequired;
  return value > 0 ? HabitDayState.partial : HabitDayState.open;
}

/// Totals of a habit: days with the goal met, the current streak and this month's figures (Fluxos
/// §15.3, §24.2).
class HabitStats {
  const HabitStats({required this.totalDays, required this.streak, required this.monthDays, required this.monthRate});

  final int totalDays;

  /// Consecutive due days met up to today; today still open does not break it, skipped days neither.
  final int streak;
  final int monthDays;

  /// Days met / due days of the month so far, 0-100.
  final int monthRate;
}

HabitStats habitStats(Habit h, List<HabitCheckin> checkins, DateTime now) {
  final today = startOfDay(now);
  final byDay = {for (final c in checkins) habitDay(c.day): c};
  bool met(DateTime d) => habitDayState(h, byDay[d], d) == HabitDayState.done;
  final totalDays = byDay.keys.where(met).length;

  var streak = 0;
  if (h.frequency == HabitFrequency.weekly) {
    // N times a week: consecutive weeks (Sunday first) with the count met; this week counts once met.
    var weekStart = startOfWeek(today);
    var current = true;
    while (!weekStart.add(const Duration(days: 6)).isBefore(habitStart(h))) {
      final count = List.generate(7, (i) => weekStart.add(Duration(days: i))).where(met).length;
      if (count >= h.perWeek) {
        streak += count;
      } else if (!current) {
        break;
      }
      current = false;
      weekStart = weekStart.subtract(const Duration(days: 7));
    }
  } else {
    var d = today;
    if (!met(d) && habitDayState(h, byDay[d], d) != HabitDayState.skipped) d = d.subtract(const Duration(days: 1));
    while (!d.isBefore(habitStart(h))) {
      final state = habitDayState(h, byDay[d], d);
      if (state == HabitDayState.done) {
        streak++;
      } else if (state != HabitDayState.notRequired && state != HabitDayState.skipped) {
        break;
      }
      d = d.subtract(const Duration(days: 1));
    }
  }

  final monthStart = DateTime(today.year, today.month);
  final monthDays = [for (var d = monthStart; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) d];
  final due = monthDays.where((d) => habitIsDue(h, d)).length;
  final done = monthDays.where(met).length;
  return HabitStats(totalDays: totalDays, streak: streak, monthDays: done, monthRate: due == 0 ? 0 : (100 * done / due).round().clamp(0, 100));
}
