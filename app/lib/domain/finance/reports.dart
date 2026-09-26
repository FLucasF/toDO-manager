import '../../data/db/database.dart';
import 'finance.dart';

/// A category's slice of a month's expenses (null category = "Sem categoria").
typedef CategorySlice = ({FinCategory? category, int amount});

/// A month's expenses by category, biggest first.
List<CategorySlice> expensesByCategory(FinanceSnapshot s, DateTime month) {
  final slices = [
    for (final MapEntry(key: id, value: amount) in spendingByCategory(s, month).entries)
      if (amount > 0) (category: id == null ? null : s.categoryById[id], amount: amount),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
}

/// Income and expenses of the [count] months ending on [last] (oldest first).
List<({DateTime month, FinTotals totals})> monthlyTotals(FinanceSnapshot s, DateTime last, int count) => [
  for (var i = count - 1; i >= 0; i--)
    if (DateTime(last.year, last.month - i) case final month) (month: month, totals: totalsOf(entriesOfMonth(s, month))),
];

/// One line of "Comparação entre meses": a category's expenses in two months.
typedef CategoryComparison = ({FinCategory? category, int first, int second});

/// Expenses by category in [first] and [second], the categories of either month, biggest first.
List<CategoryComparison> compareMonths(FinanceSnapshot s, DateTime first, DateTime second) {
  final a = spendingByCategory(s, first), b = spendingByCategory(s, second);
  final ids = {...a.keys, ...b.keys};
  final rows = [
    for (final id in ids)
      if ((a[id] ?? 0) > 0 || (b[id] ?? 0) > 0) (category: id == null ? null : s.categoryById[id], first: a[id] ?? 0, second: b[id] ?? 0),
  ]..sort((x, y) => (y.first + y.second).compareTo(x.first + x.second));
  return rows;
}

/// The change from [before] to [after] in hundredths of a percent; null when [before] is zero.
int? changeBasisPoints(int before, int after) => before == 0 ? null : ((after - before) * 10000 / before).round();
