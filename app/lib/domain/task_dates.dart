import '../core/clock.dart';
import '../data/db/database.dart';

/// Start and end of a task ("Duração"). As in TickTick, `dueDate` is the end and
/// `startDate` the start; without a duration both are the same. For all-day ranges both are local
/// midnights and the end day is included.
extension TaskDates on Task {
  DateTime? get startLocal => (startDate ?? dueDate)?.toLocal();
  DateTime? get endLocal => dueDate?.toLocal();

  bool get hasDuration {
    final start = startDate, end = dueDate;
    return start != null && end != null && start.isBefore(end);
  }

  /// Days from [today] to the start (negative when it already started), or null without a date.
  int? daysToStart(DateTime today) {
    final start = startLocal;
    return start == null ? null : daysBetween(today, start);
  }

  /// Days from [today] to the end; negative = overdue.
  int? daysToEnd(DateTime today) {
    final end = endLocal;
    return end == null ? null : daysBetween(today, end);
  }

  /// Whether the task takes place on [day] (inclusive range).
  bool isOn(DateTime day) {
    final toStart = daysToStart(day), toEnd = daysToEnd(day);
    return toStart != null && toEnd != null && toStart <= 0 && toEnd >= 0;
  }
}
