import '../../data/db/database.dart';
import 'finance.dart';
import 'finance_enums.dart';

/// Where one occurrence of a recurring bill stands.
enum OccurrenceStatus { paid, pending, overdue }

/// One due day of a recurring bill, and the entry that paid it (if any).
class Occurrence {
  const Occurrence({required this.recurring, required this.due, required this.status, this.entry});

  final FinRecurring recurring;
  final DateTime due;
  final OccurrenceStatus status;
  final FinEntry? entry;
}

/// The due days of [r] from [from] to [to] (both included), within its start and end.
List<DateTime> dueDays(FinRecurring r, DateTime from, DateTime to) {
  final start = finDay(r.startDate), end = r.endDate == null ? null : finDay(r.endDate!);
  final days = <DateTime>[];
  for (var m = DateTime(from.year, from.month); !m.isAfter(to); m = DateTime(m.year, m.month + 1)) {
    if (r.frequency == FinFrequency.yearly && m.month != (r.month ?? start.month)) continue;
    final day = clampedDay(m.year, m.month, r.day);
    if (day.isBefore(from) || day.isAfter(to) || day.isBefore(start) || (end != null && day.isAfter(end))) continue;
    days.add(day);
  }
  return days;
}

/// The occurrences of every active recurring bill from [from] to [to], by due day.
List<Occurrence> occurrences(FinanceSnapshot s, DateTime from, DateTime to, DateTime today) {
  final paid = <(String, DateTime), FinEntry>{
    for (final e in s.entries)
      if (e.recurringId != null && e.recurringDue != null) (e.recurringId!, finDay(e.recurringDue!)): e,
  };
  final day = DateTime(today.year, today.month, today.day);
  return [
    for (final r in s.recurrings)
      if (r.archivedAt == null)
        for (final due in dueDays(r, from, to))
          Occurrence(
            recurring: r,
            due: due,
            entry: paid[(r.id, due)],
            status: paid.containsKey((r.id, due))
                ? OccurrenceStatus.paid
                : due.isBefore(day)
                ? OccurrenceStatus.overdue
                : OccurrenceStatus.pending,
          ),
  ]..sort((a, b) => a.due.compareTo(b.due));
}

/// Unpaid occurrences before [today], back to a year: the "Atrasadas" above the month.
List<Occurrence> overdueOccurrences(FinanceSnapshot s, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  return [
    for (final o in occurrences(s, DateTime(day.year - 1, day.month, day.day), day.subtract(const Duration(days: 1)), day))
      if (o.status == OccurrenceStatus.overdue) o,
  ];
}
