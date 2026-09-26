import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/finance/finance.dart';
import '../../domain/finance/loans.dart';
import '../../domain/finance/money.dart';
import '../../domain/finance/reports.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../statistics/charts.dart';
import 'finance_widgets.dart';
import 'loans_tab.dart';

/// Colors of the categories without one of their own, in order.
const _sliceColors = [
  Color(0xFF4772FA),
  Color(0xFFE5484D),
  Color(0xFFF5A524),
  Color(0xFF30A46C),
  Color(0xFF8E4EC6),
  Color(0xFF12A594),
  Color(0xFFD6409F),
  Color(0xFF978365),
  Color(0xFF0090FF),
  Color(0xFFE54D2E),
];

/// "Relatórios": the month's expenses by category, income × expenses of the last 6 months, one
/// month against another by category, and the loans.
class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  late DateTime _month = monthOf(ref.read(clockProvider).now());

  /// The month compared with [_month]; the one before it to begin with.
  DateTime? _other;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(financeProvider).value ?? FinanceSnapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final other = _other ?? DateTime(_month.year, _month.month - 1);
    final slices = expensesByCategory(s, _month);
    final spent = slices.fold(0, (sum, x) => sum + x.amount);
    Color colorOf(int i, CategorySlice slice) => parseHexColor(slice.category?.color) ?? _sliceColors[i % _sliceColors.length];
    final months = monthlyTotals(s, _month, 6);
    final compared = compareMonths(s, other, _month);

    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tt.text),
      ),
    );

    Widget monthButton(DateTime month, ValueChanged<DateTime> onChanged) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        Text(
          dates.monthTitle(month),
          style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );

    final legend = Column(
      children: [
        for (final (i, slice) in slices.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: colorOf(i, slice), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${slice.category?.icon ?? ''} ${categoryName(t, slice.category)}'.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tt.text),
                  ),
                ),
                Text(
                  formatPercent((slice.amount * 100 / spent).round() * 100),
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
                const SizedBox(width: 12),
                Text(
                  formatMoney(slice.amount),
                  style: TextStyle(color: tt.text, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
    final donut = DonutChart(
      size: 150,
      parts: [for (final (i, slice) in slices.indexed) (slice.amount.toDouble(), colorOf(i, slice))],
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.finExpenses, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
          FittedBox(
            child: Text(
              formatMoney(spent),
              style: TextStyle(fontWeight: FontWeight.w700, color: tt.text),
            ),
          ),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(narrow ? 12 : 20, 4, narrow ? 12 : 20, 32),
      children: [
        Align(alignment: Alignment.centerLeft, child: monthButton(_month, (m) => setState(() => _month = m))),
        title(t.finByCategory),
        if (slices.isEmpty)
          Text(t.finNoExpenses, style: TextStyle(color: tt.textTertiary))
        else if (narrow)
          Column(children: [donut, const SizedBox(height: 12), legend])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              donut,
              const SizedBox(width: 32),
              Expanded(child: legend),
            ],
          ),
        title(t.finIncomeVsExpenses),
        PairedBarChart(
          labels: [for (final m in months) dates.monthShort(m.month)],
          first: [for (final m in months) m.totals.income],
          second: [for (final m in months) m.totals.expense],
          firstColor: tt.palette.green,
          secondColor: tt.overdue,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final m in months.reversed.take(3))
              Text(
                '${dates.monthShort(m.month)}: ${t.finBalance} ${formatMoney(m.totals.balance)}',
                style: TextStyle(fontSize: TtText.small, color: m.totals.balance < 0 ? tt.overdue : tt.textSecondary),
              ),
          ],
        ),
        title(t.finCompareMonths),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            monthButton(other, (m) => setState(() => _other = m)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(t.finVersus, style: TextStyle(color: tt.textTertiary)),
            ),
            monthButton(_month, (m) => setState(() => _month = m)),
          ],
        ),
        if (compared.isEmpty)
          Text(t.finNoExpenses, style: TextStyle(color: tt.textTertiary))
        else
          _CompareTable(rows: compared, first: dates.monthShort(other), second: dates.monthShort(_month)),
        title(t.finLoansSummary),
        LoansOverviewCards(overview: loansOverview(loanSummaries(s, today))),
      ],
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({required this.rows, required this.first, required this.second});

  final List<CategoryComparison> rows;
  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final head = TextStyle(fontSize: TtText.small, color: tt.textTertiary, fontWeight: FontWeight.w600);
    final firstTotal = rows.fold(0, (sum, r) => sum + r.first), secondTotal = rows.fold(0, (sum, r) => sum + r.second);

    Widget row(String name, int a, int b, {bool bold = false}) {
      final change = changeBasisPoints(a, b);
      final style = TextStyle(color: tt.text, fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(formatMoney(a), textAlign: TextAlign.end, style: style),
            ),
            Expanded(
              flex: 2,
              child: Text(formatMoney(b), textAlign: TextAlign.end, style: style),
            ),
            SizedBox(
              width: 64,
              child: Text(
                change == null ? '—' : '${change > 0 ? '+' : ''}${formatPercent(change)}',
                textAlign: TextAlign.end,
                // Spending more is red; less, green.
                style: TextStyle(
                  fontSize: TtText.small,
                  color: change == null || change == 0
                      ? tt.textTertiary
                      : change > 0
                      ? tt.overdue
                      : tt.palette.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text(t.finCategory, style: head)),
            Expanded(
              flex: 2,
              child: Text(first, textAlign: TextAlign.end, style: head),
            ),
            Expanded(
              flex: 2,
              child: Text(second, textAlign: TextAlign.end, style: head),
            ),
            SizedBox(
              width: 64,
              child: Text(t.finChange, textAlign: TextAlign.end, style: head),
            ),
          ],
        ),
        for (final r in rows) row('${r.category?.icon ?? ''} ${categoryName(t, r.category)}'.trim(), r.first, r.second),
        Divider(color: tt.divider),
        row(t.finTotal, firstTotal, secondTotal, bold: true),
      ],
    );
  }
}

/// Two bars per label side by side (income and expenses of each month).
class PairedBarChart extends StatelessWidget {
  const PairedBarChart({
    super.key,
    required this.labels,
    required this.first,
    required this.second,
    required this.firstColor,
    required this.secondColor,
    this.height = 170,
  });

  final List<String> labels;
  final List<int> first;
  final List<int> second;
  final Color firstColor;
  final Color secondColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _PairedBarPainter(
          labels: labels,
          first: first,
          second: second,
          firstColor: firstColor,
          secondColor: secondColor,
          grid: tt.divider,
          label: TextStyle(fontSize: 11, color: tt.textTertiary),
        ),
      ),
    );
  }
}

class _PairedBarPainter extends CustomPainter {
  const _PairedBarPainter({
    required this.labels,
    required this.first,
    required this.second,
    required this.firstColor,
    required this.secondColor,
    required this.grid,
    required this.label,
  });

  final List<String> labels;
  final List<int> first;
  final List<int> second;
  final Color firstColor;
  final Color secondColor;
  final Color grid;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final top = [...first, ...second].fold(0, math.max);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), Paint()..color = grid);
    if (labels.isEmpty) return;
    final slot = size.width / labels.length;
    final bar = math.min(18.0, slot / 3);
    for (var i = 0; i < labels.length; i++) {
      final center = slot * i + slot / 2;
      for (final (value, color, dx) in [(first[i], firstColor, -bar - 1), (second[i], secondColor, 1.0)]) {
        final h = top == 0 ? 0.0 : chartHeight * value / top;
        if (h > 0) {
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(center + dx, chartHeight - h, bar, h),
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
            Paint()..color = color,
          );
        }
      }
      final text = TextPainter(
        text: TextSpan(text: labels[i], style: label),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: slot);
      text.paint(canvas, Offset(center - text.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(_PairedBarPainter old) => old.first != first || old.second != second || old.labels != labels;
}
