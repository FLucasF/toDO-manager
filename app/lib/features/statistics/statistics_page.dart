import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/focus_controller.dart';
import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/habits.dart';
import '../../domain/snapshot.dart';
import '../../domain/statistics.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';
import '../focus/focus_page.dart' show focusRecordsProvider;
import '../focus/focus_timers.dart' show focusLinkName;
import '../habits/habit_widgets.dart';
import 'charts.dart';

/// Tabs of the statistics (`#statistics/{tab}`).
enum StatsTab {
  overview('overview'),
  task('task'),
  pomo('pomo');

  const StatsTab(this.route);
  final String route;

  static StatsTab fromRoute(String? route) => values.where((t) => t.route == route).firstOrNull ?? overview;
}

/// A dropdown's text: its own style replaces the inherited one, so it starts from the app's font.
TextStyle _dropdownStyle(BuildContext context) =>
    DefaultTextStyle.of(context).style.copyWith(fontSize: TtText.small, color: context.tt.textSecondary);

String _duration(AppLocalizations t, Duration d) => focusDuration(d, hours: t.focusHours, minutes: t.focusMins);

/// Estatísticas: Visão geral · Tarefa · Foco, and "Concluído" to close.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key, required this.tab});

  final StatsTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    Widget tabButton(StatsTab value, String label) => TextButton(
      onPressed: () => context.go(Routes.statisticsOf(value.route)),
      style: TextButton.styleFrom(foregroundColor: value == tab ? tt.primary : tt.textSecondary),
      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: value == tab ? FontWeight.w700 : FontWeight.w400)),
    );
    return Scaffold(
      backgroundColor: tt.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(narrow ? 8 : 24, 12, narrow ? 20 : 24, 4),
              child: Row(
                children: [
                  tabButton(StatsTab.overview, t.statsOverview),
                  tabButton(StatsTab.task, t.statsTask),
                  tabButton(StatsTab.pomo, t.statsFocus),
                  const Spacer(),
                  FilledButton(onPressed: () => context.go(Routes.initial), child: Text(t.statsDone)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: switch (tab) {
                    StatsTab.overview => const _Overview(),
                    StatsTab.task => const _TaskTab(),
                    StatsTab.pomo => const _FocusTab(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ shared pieces

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A number with its label ("12 · Conclusão de Hoje") and, optionally, the change from the previous period.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.change});

  final String value;
  final String label;
  final String? change;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tt.text),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
          ),
          if (change != null) Text(change!, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
        ],
      ),
    );
  }
}

/// Figures in rows of [perRow].
Widget _figures(List<Widget> items, {int perRow = 3}) => LayoutBuilder(
  builder: (context, box) {
    final columns = box.maxWidth < 520 ? 2 : perRow;
    const gap = 10.0;
    final width = (box.maxWidth - gap * (columns - 1)) / columns;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final i in items) SizedBox(width: width, child: i)],
      ),
    );
  },
);

/// Dia / Semana / Mês toggle.
class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.value, required this.onChanged, this.adverbs = false});

  final StatsPeriod value;
  final ValueChanged<StatsPeriod> onChanged;

  /// "Diariamente / Semanalmente / Mensalmente" (the Tarefa tab).
  final bool adverbs;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DropdownButton<StatsPeriod>(
      value: value,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: _dropdownStyle(context),
      items: [
        DropdownMenuItem(value: StatsPeriod.day, child: Text(adverbs ? t.statsDaily : t.calendarModeDay)),
        DropdownMenuItem(value: StatsPeriod.week, child: Text(adverbs ? t.statsWeekly : t.calendarModeWeek)),
        DropdownMenuItem(value: StatsPeriod.month, child: Text(adverbs ? t.statsMonthly : t.calendarModeMonth)),
      ],
      onChanged: (p) => p == null ? null : onChanged(p),
    );
  }
}

String _periodLabel(AppLocalizations t, StatsPeriod p, DateTime start, DateTime today) {
  final dates = DateLabels(t);
  return switch (p) {
    StatsPeriod.day => dates.dayHeader(start, today),
    StatsPeriod.week => () {
      final end = DateTime(start.year, start.month, start.day + 6);
      return '${start.day} ${dates.monthShort(start)} - ${end.day} ${dates.monthShort(end)}';
    }(),
    StatsPeriod.month => dates.monthTitle(start),
  };
}

/// ‹ period label ›, with "Hoje" when away from the current period.
class _PeriodNav extends StatelessWidget {
  const _PeriodNav({required this.period, required this.start, required this.today, required this.onChanged});

  final StatsPeriod period;
  final DateTime start;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final current = periodStart(period, today);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.chevron_left, size: 18, color: tt.textSecondary),
          onPressed: () => onChanged(periodStart(period, DateTime(start.year, start.month, start.day - 1))),
        ),
        Text(
          _periodLabel(t, period, start, today),
          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.chevron_right, size: 18, color: start == current ? tt.textFaint : tt.textSecondary),
          onPressed: start == current ? null : () => onChanged(periodEnd(period, start)),
        ),
        if (start != current) TextButton(onPressed: () => onChanged(current), child: Text(t.calendarToday)),
      ],
    );
  }
}

String _groupName(AppLocalizations t, Snapshot s, StatsGrouping g, String key) {
  final labels = Labels(t);
  if (key.isEmpty) return t.statsUnlinked;
  return switch (g) {
    StatsGrouping.list => s.listById[key] == null ? '?' : labels.listName(s.listById[key]!),
    StatsGrouping.tag => s.tagById[key]?.name ?? '?',
    StatsGrouping.priority => labels.priority(Priority.fromCode(int.tryParse(key) ?? 0)),
    StatsGrouping.task => focusLinkName(t, s, key) ?? '?',
  };
}

/// Horizontal bars with a name and a value ("Estatísticas de conclusão", "Detalhes").
class _Ranking extends StatelessWidget {
  const _Ranking({required this.rows});

  final List<(String, double, String)> rows;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          t.statsNoData,
          textAlign: TextAlign.center,
          style: TextStyle(color: tt.textTertiary),
        ),
      );
    }
    final top = rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final (name, value, label) in rows.take(10))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: TtText.small, color: tt.text),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: top <= 0 ? 0 : value / top, minHeight: 8, color: tt.primary, backgroundColor: tt.divider),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    label,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _shortLabel(AppLocalizations t, StatsPeriod p, DateTime start) {
  final dates = DateLabels(t);
  return switch (p) {
    StatsPeriod.day => '${start.day}/${start.month}',
    StatsPeriod.week => '${start.day}/${start.month}',
    StatsPeriod.month => dates.monthShort(start),
  };
}

String _signed(num n) => n > 0 ? '+$n' : '$n';

// ------------------------------------------------------------------ Visão geral

class _Overview extends ConsumerStatefulWidget {
  const _Overview();

  @override
  ConsumerState<_Overview> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<_Overview> {
  StatsPeriod _period = StatsPeriod.day;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final records = ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[];
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final forever = DateTime(1970);
    final live = s.tasks.where((task) => task.deletedAt == null).toList();
    final score = achievementScore(s, now);
    final level = achievementLevel(score);
    final periods = recentPeriods(_period, today);
    final labels = [for (final p in periods) _shortLabel(t, _period, p)];
    List<double> series(double Function(DateTime from, DateTime to) f) => [for (final p in periods) f(p, periodEnd(_period, p))];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _figures(perRow: 4, [
          _Figure(value: '${live.length}', label: t.statsTasksLabel),
          _Figure(value: '${live.where((task) => task.status == TaskStatus.completed).length}', label: t.statsCompletedLabel),
          _Figure(value: '${s.activeLists.length}', label: t.statsListsLabel),
          _Figure(value: '${daysOfUse(s, now)}', label: t.statsDaysLabel),
        ]),
        _figures([
          _Figure(value: '${completedBetween(s, today, tomorrow).length}', label: t.statsTodayCompletion),
          _Figure(value: '${pomosBetween(records, today, tomorrow)}', label: t.focusTodayPomos),
          _Figure(value: _duration(t, focusBetween(records, today, tomorrow)), label: t.focusTodayDuration),
          _Figure(value: '${completedBetween(s, forever, tomorrow).length}', label: t.statsTotalCompletion),
          _Figure(value: '${pomosBetween(records, forever, tomorrow)}', label: t.focusTotalPomos),
          _Figure(value: _duration(t, focusBetween(records, forever, tomorrow)), label: t.focusTotalDuration),
        ]),
        _Card(
          title: t.statsAchievement,
          child: Row(
            children: [
              Text(
                '$score',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: tt.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.statsLevel(level.level),
                      style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: level.next == null
                          ? 1
                          : (score - (level.level == 1 ? 0 : achievementLevels[level.level - 2])) /
                                (level.next! - (level.level == 1 ? 0 : achievementLevels[level.level - 2])),
                      minHeight: 6,
                      color: tt.primary,
                      backgroundColor: tt.divider,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.next == null ? t.statsTopLevel : t.statsNextLevel(level.level + 1, level.next! - score),
                      style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Card(
          title: t.statsCompletionCurve,
          trailing: _PeriodPicker(value: _period, onChanged: (p) => setState(() => _period = p)),
          child: LineChart(
            values: series((from, to) => completedBetween(s, from, to).length.toDouble()),
            labels: labels,
            format: (v) => '${v.round()}',
          ),
        ),
        _Card(
          title: t.statsRateCurve,
          child: LineChart(
            values: series((from, to) => (completionRate(s, from, to) ?? 0) * 100),
            labels: labels,
            maxValue: 100,
            format: (v) => '${v.round()}%',
          ),
        ),
        _Card(
          title: t.statsPomoCurve,
          child: LineChart(values: series((from, to) => pomosBetween(records, from, to).toDouble()), labels: labels, format: (v) => '${v.round()}'),
        ),
        _Card(
          title: t.statsFocusCurve,
          child: LineChart(
            values: series((from, to) => focusBetween(records, from, to).inMinutes.toDouble()),
            labels: labels,
            format: (v) => _duration(t, Duration(minutes: v.round())),
          ),
        ),
        _Card(
          title: t.statsHabitsWeek,
          child: _HabitsWeek(today: today),
        ),
        _Card(
          title: t.statsMedals,
          child: Wrap(spacing: 12, runSpacing: 12, children: [for (final m in medals(s, records, now)) _MedalTile(medal: m)]),
        ),
      ],
    );
  }
}

class _HabitsWeek extends ConsumerWidget {
  const _HabitsWeek({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final habits = s.habits.where((h) => h.deletedAt == null && h.archivedAt == null).toList();
    if (habits.isEmpty) return Text(t.statsNoHabits, style: TextStyle(color: tt.textTertiary));
    final week = periodStart(StatsPeriod.week, today);
    final days = [for (var i = 0; i < 7; i++) DateTime(week.year, week.month, week.day + i)];
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 180),
            for (final d in days)
              Expanded(
                child: Text(
                  dates.weekdayShort(d),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: d == today ? tt.primary : tt.textTertiary),
                ),
              ),
          ],
        ),
        for (final h in habits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: Row(
                    children: [
                      HabitIcon(habit: h, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: TtText.small, color: tt.text),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final d in days)
                  Expanded(
                    child: Center(
                      child: switch (habitDayState(h, s.checkinsOf(h.id).where((c) => habitDay(c.day) == d).firstOrNull, d)) {
                        HabitDayState.done => Icon(Icons.check_circle, size: 18, color: tt.primary),
                        HabitDayState.failed => Icon(Icons.cancel, size: 18, color: tt.textFaint),
                        _ => Icon(Icons.circle_outlined, size: 18, color: habitIsDue(h, d) ? tt.textFaint : tt.divider),
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Tarefa

class _TaskTab extends ConsumerStatefulWidget {
  const _TaskTab();

  @override
  ConsumerState<_TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends ConsumerState<_TaskTab> {
  StatsPeriod _period = StatsPeriod.day;
  DateTime? _start;
  StatsGrouping _grouping = StatsGrouping.list;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final start = _start ?? periodStart(_period, today);
    final end = periodEnd(_period, start);
    final previous = periodStart(_period, DateTime(start.year, start.month, start.day - 1));
    final done = completedBetween(s, start, end).length;
    final doneBefore = completedBetween(s, previous, start).length;
    final rate = completionRate(s, start, end);
    final rateBefore = completionRate(s, previous, start);
    final vs = switch (_period) {
      StatsPeriod.day => t.statsVsDay,
      StatsPeriod.week => t.statsVsWeek,
      StatsPeriod.month => t.statsVsMonth,
    };
    final dist = completionDistribution(s, start, end);
    final colors = [tt.primary, tt.palette.priorityMedium, tt.textFaint];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        Row(
          children: [
            _PeriodPicker(
              value: _period,
              adverbs: true,
              onChanged: (p) => setState(() {
                _period = p;
                _start = null;
              }),
            ),
            const Spacer(),
            _PeriodNav(period: _period, start: start, today: today, onChanged: (d) => setState(() => _start = d)),
          ],
        ),
        const SizedBox(height: 8),
        _figures(perRow: 2, [
          _Figure(value: '$done', label: t.statsTaskCompleted, change: '$vs ${_signed(done - doneBefore)}'),
          _Figure(
            value: rate == null ? '-' : '${(rate * 100).round()}%',
            label: t.statsRate,
            change: rate == null || rateBefore == null ? null : '$vs ${_signed(((rate - rateBefore) * 100).round())}%',
          ),
        ]),
        _Card(
          title: t.statsDistribution,
          child: Row(
            children: [
              DonutChart(
                parts: [(dist.onTime.toDouble(), colors[0]), (dist.late.toDouble(), colors[1]), (dist.undone.toDouble(), colors[2])],
                center: Text(
                  rate == null ? '-' : '${(rate * 100).round()}%',
                  style: TextStyle(fontWeight: FontWeight.w700, color: tt.text),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, (label, n)) in [(t.statsOnTime, dist.onTime), (t.statsLate, dist.late), (t.statsUndone, dist.undone)].indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                              ),
                            ),
                            Text(
                              '$n',
                              style: TextStyle(fontSize: TtText.small, color: tt.text),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Card(
          title: t.statsByCategory,
          trailing: DropdownButton<StatsGrouping>(
            value: _grouping,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: _dropdownStyle(context),
            items: [
              DropdownMenuItem(value: StatsGrouping.list, child: Text(t.statsByList)),
              DropdownMenuItem(value: StatsGrouping.tag, child: Text(t.statsByTag)),
              DropdownMenuItem(value: StatsGrouping.priority, child: Text(t.statsByPriority)),
            ],
            onChanged: (g) => g == null ? null : setState(() => _grouping = g),
          ),
          child: _Ranking(
            rows: [for (final (key, n) in completedBy(s, start, end, _grouping)) (_groupName(t, s, _grouping, key), n.toDouble(), '$n')],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Foco

class _FocusTab extends ConsumerStatefulWidget {
  const _FocusTab();

  @override
  ConsumerState<_FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends ConsumerState<_FocusTab> {
  StatsPeriod _period = StatsPeriod.day;
  DateTime? _start;
  StatsGrouping _grouping = StatsGrouping.list;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final records = ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[];
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final forever = DateTime(1970);
    final start = _start ?? periodStart(_period, today);
    final end = periodEnd(_period, start);
    final week = periodStart(StatsPeriod.week, start);
    final weekDays = [for (var i = 0; i < 7; i++) DateTime(week.year, week.month, week.day + i)];
    final weekMinutes = [for (final d in weekDays) focusBetween(records, d, DateTime(d.year, d.month, d.day + 1)).inMinutes.toDouble()];
    final month = DateTime(start.year, start.month);
    final monthDays = daysBetween(month, DateTime(month.year, month.month + 1));
    final byHourMonth = focusByHour(records, month, monthDays);
    final hourTotals = [for (var h = 0; h < 24; h++) byHourMonth.fold(0.0, (sum, day) => sum + day[h])];
    final year = DateTime(start.year);
    final yearStart = periodStart(StatsPeriod.week, year);
    final yearWeeks = (daysBetween(yearStart, DateTime(start.year + 1)) / 7).ceil();
    final pomosToday = pomosBetween(records, today, tomorrow), pomosYesterday = pomosBetween(records, yesterday, today);
    final focusToday = focusBetween(records, today, tomorrow), focusYesterday = focusBetween(records, yesterday, today);
    final details = focusBy(s, records, start, end, _grouping);
    final shown = [
      for (final r in records)
        if (r.deletedAt == null && !r.startedAt.toLocal().isBefore(start) && r.startedAt.toLocal().isBefore(end)) r,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _figures(perRow: 4, [
          _Figure(value: '$pomosToday', label: t.focusTodayPomos, change: '${t.statsVsDay} ${_signed(pomosToday - pomosYesterday)}'),
          _Figure(value: '${pomosBetween(records, forever, tomorrow)}', label: t.focusTotalPomos),
          _Figure(
            value: _duration(t, focusToday),
            label: t.focusTodayDuration,
            change: '${t.statsVsDay} ${_signed(focusToday.inMinutes - focusYesterday.inMinutes)}m',
          ),
          _Figure(value: _duration(t, focusBetween(records, forever, tomorrow)), label: t.focusTotalDuration),
        ]),
        Row(
          children: [
            _PeriodPicker(
              value: _period,
              onChanged: (p) => setState(() {
                _period = p;
                _start = null;
              }),
            ),
            const Spacer(),
            _PeriodNav(period: _period, start: start, today: today, onChanged: (d) => setState(() => _start = d)),
          ],
        ),
        const SizedBox(height: 8),
        _Card(
          title: t.statsFocusDetails,
          trailing: DropdownButton<StatsGrouping>(
            value: _grouping,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: _dropdownStyle(context),
            items: [
              DropdownMenuItem(value: StatsGrouping.list, child: Text(t.statsByList)),
              DropdownMenuItem(value: StatsGrouping.tag, child: Text(t.statsByTag)),
              DropdownMenuItem(value: StatsGrouping.task, child: Text(t.statsByTask)),
            ],
            onChanged: (g) => g == null ? null : setState(() => _grouping = g),
          ),
          child: _Ranking(rows: [for (final (key, d) in details) (_groupName(t, s, _grouping, key), d.inMinutes.toDouble(), _duration(t, d))]),
        ),
        _Card(
          title: t.focusRecords.replaceAll('.', ''),
          child: shown.isEmpty
              ? Text(t.focusRecordsEmpty, style: TextStyle(color: tt.textTertiary))
              : Column(
                  children: [
                    for (final r in shown.take(20))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                '${DateLabels.time(r.startedAt.toLocal())} - ${DateLabels.time(r.endedAt.toLocal())}',
                                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                focusLinkName(t, s, r.taskId) ?? t.statsUnlinked,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: TtText.small, color: tt.text),
                              ),
                            ),
                            Text(
                              _duration(t, Duration(seconds: r.seconds)),
                              style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        _Card(
          title: t.statsTrends,
          trailing: Text(
            t.statsDailyAverage(_duration(t, Duration(minutes: (weekMinutes.fold(0.0, (a, b) => a + b) / 7).round()))),
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          child: BarChart(
            values: weekMinutes,
            labels: [for (final d in weekDays) dates.weekdayShort(d)],
            highlight: weekDays.contains(today) ? weekDays.indexOf(today) : null,
            format: (v) => _duration(t, Duration(minutes: v.round())),
          ),
        ),
        _Card(
          title: t.statsWeekTimeline,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HeatGrid(
              values: focusByHour(records, week, 7),
              levelOf: (m) => m <= 0 ? 0 : (m < 15 ? 1 : (m < 30 ? 2 : (m < 45 ? 3 : 4))),
              cell: 16,
              rowLabels: [for (final d in weekDays) dates.weekdayShort(d)],
              colLabels: {for (var h = 0; h < 24; h += 3) h: '$h'},
            ),
          ),
        ),
        _Card(
          title: t.statsMostFocused,
          child: BarChart(values: hourTotals, labels: [for (var h = 0; h < 24; h++) h % 3 == 0 ? '$h' : '']),
        ),
        _Card(
          title: t.statsYearGrid,
          trailing: Text(
            '${start.year}',
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: HeatGrid(
                  // Rows are weekdays (Sunday first), columns the weeks of the year.
                  values: [
                    for (var wd = 0; wd < 7; wd++)
                      [
                        for (var w = 0; w < yearWeeks; w++)
                          if (DateTime(yearStart.year, yearStart.month, yearStart.day + 7 * w + wd) case final d)
                            d.year != start.year ? -1.0 : focusBetween(records, d, DateTime(d.year, d.month, d.day + 1)).inMinutes.toDouble(),
                      ],
                  ],
                  levelOf: (m) => m < 0 ? 0 : focusDayLevel(Duration(minutes: m.round())),
                  cell: 11,
                  rowLabels: [
                    for (var wd = 0; wd < 7; wd++) wd.isOdd ? dates.weekdayShort(DateTime(yearStart.year, yearStart.month, yearStart.day + wd)) : '',
                  ],
                  colLabels: {
                    for (var m = 1; m <= 12; m++) (daysBetween(yearStart, DateTime(start.year, m)) ~/ 7): dates.monthShort(DateTime(start.year, m)),
                  },
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  for (final (i, label) in ['0m', '0-1h', '1h-3h', '3h-5h', '>5h'].indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: i == 0 ? tt.fieldFill : tt.primary.withValues(alpha: 0.2 + 0.2 * i),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(label, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A medal: its icon (grey while locked), name, level and the way to the next one.
class _MedalTile extends StatelessWidget {
  const _MedalTile({required this.medal});

  final Medal medal;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final (icon, name, unit) = switch (medal.kind) {
      MedalKind.perseverance => (Icons.local_fire_department, t.medalPerseverance, t.statsDaysLabel),
      MedalKind.getThingsDone => (Icons.task_alt, t.medalGetThingsDone, t.statsTasksLabel),
      MedalKind.mindfulness => (Icons.self_improvement, t.medalMindfulness, t.medalMinutes),
      MedalKind.selfDiscipline => (Icons.military_tech, t.medalSelfDiscipline, t.medalCheckins),
    };
    final locked = medal.level == 0;
    final next = medal.next;
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: locked ? tt.divider : tt.primary.withValues(alpha: 0.2),
            child: Icon(icon, color: locked ? tt.textFaint : tt.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                ),
                Text(
                  locked ? t.medalLocked : t.statsLevel(medal.level),
                  style: TextStyle(fontSize: TtText.small, color: locked ? tt.textTertiary : tt.primary),
                ),
                Text(next == null ? '${medal.value} $unit' : '${medal.value} / $next $unit', style: TextStyle(fontSize: 11, color: tt.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
