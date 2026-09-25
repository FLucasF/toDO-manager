import 'dart:async';

import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../app/routes.dart';
import '../../app/focus_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/habits.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../shell/app_shell.dart';
import 'habit_export.dart';
import 'habit_form.dart';
import 'habit_gallery.dart';
import 'habit_widgets.dart';

HabitCheckin? _checkinOn(Snapshot s, String habitId, DateTime day) =>
    s.checkinsOf(habitId).where((c) => daysBetween(habitDay(c.day), day) == 0).firstOrNull;

/// "Configurações de hábitos", also opened from Settings → Funcionalidades.
Future<void> showHabitSettings(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final t = AppLocalizations.of(context);
      final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
      final repo = ref.read(preferencesRepositoryProvider);
      return AlertDialog(
        title: Text(t.featureHabitSettings, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(t.habitShowInToday),
                value: prefs.habitsInToday,
                onChanged: (v) => unawaited(repo.setHabitsInToday(enabled: v)),
              ),
              SwitchListTile(
                title: Text(t.habitSortByStatus),
                subtitle: Text(t.habitSortByStatusHint),
                value: prefs.habitsSortByStatus,
                onChanged: (v) => unawaited(repo.setHabitsSortByStatus(enabled: v)),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
      );
    },
  ),
);

/// Habits module (`#q/all/habit`).
class HabitPage extends ConsumerStatefulWidget {
  const HabitPage({super.key});

  @override
  ConsumerState<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends ConsumerState<HabitPage> {
  bool _archived = false;

  /// "Visão em cartão" instead of the list.
  bool _cards = false;
  DateTime? _filterDay;

  /// The habit shown in the side panel (wide screens).
  String? _selected;

  /// Wide enough for the list and the habit side by side.
  static const _panelBreakpoint = 1100.0;

  void _open(BuildContext context, String habitId) {
    if (MediaQuery.sizeOf(context).width >= _panelBreakpoint) {
      setState(() => _selected = habitId);
    } else {
      unawaited(showHabitDetail(context, habitId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final week = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final sortByStatus = ref.watch(preferencesProvider).value?.habitsSortByStatus ?? false;
    final habits = s.habits.where((h) => (h.archivedAt != null) == _archived).toList();
    if (sortByStatus) {
      int doneToday(Habit h) => habitDayState(h, _checkinOn(s, h.id, today), today) == HabitDayState.done ? 1 : 0;
      habits.sort((a, b) => doneToday(a).compareTo(doneToday(b)));
    }
    final filterDay = _filterDay;
    final shown = filterDay == null ? habits : habits.where((h) => habitIsDue(h, filterDay)).toList();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        children: [
          const DrawerMenuButton(),
          PopupMenuButton<bool>(
            tooltip: '',
            onSelected: (v) => setState(() => _archived = v),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: false, checked: !_archived, child: Text(t.habitActive)),
              CheckedPopupMenuItem(value: true, checked: _archived, child: Text(t.habitArchived)),
            ],
            child: Row(
              children: [
                Text(
                  t.navHabit,
                  style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                ),
                Icon(Icons.expand_more, size: 18, color: tt.textTertiary),
              ],
            ),
          ),
          const Spacer(),
          // Cards or list (the "habit-card" icon).
          IconButton(
            tooltip: _cards ? t.habitListView : t.habitCardView,
            icon: Icon(_cards ? Icons.view_list_outlined : Icons.grid_view_outlined, color: tt.textSecondary),
            onPressed: () => setState(() => _cards = !_cards),
          ),
          IconButton(
            tooltip: t.habitNew,
            icon: Icon(Icons.add, color: tt.textSecondary),
            // "Galeria de hábitos" with "Criar novo".
            onPressed: () => unawaited(showHabitGallery(context)),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            icon: Icon(Icons.more_horiz, color: tt.textSecondary),
            onSelected: (v) => unawaited(v == 'export' ? exportHabits(context, ref) : showHabitSettings(context)),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', height: 36, child: Text(t.habitSettings)),
              PopupMenuItem(value: 'export', height: 36, child: Text(t.habitExport)),
            ],
          ),
        ],
      ),
    );

    // The last 7 days: each shows how many of its habits are done; a click filters by that day.
    final strip = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // Aligned with the 7 dots of each row (26 px + 4 px on each side).
          const Spacer(),
          for (final d in week)
            SizedBox(
              width: 34,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _filterDay = _filterDay == d ? null : d),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: _filterDay == d ? tt.selected : null, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text(dates.weekdayShort(d), style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final due = habits.where((h) => habitIsDue(h, d)).toList();
                                final done = due.where((h) => habitDayState(h, _checkinOn(s, h.id, d), d) == HabitDayState.done).length;
                                return SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: due.isEmpty ? 0 : done / due.length,
                                    strokeWidth: 2.5,
                                    color: tt.primary,
                                    backgroundColor: tt.divider,
                                  ),
                                );
                              },
                            ),
                            Text('${d.day}', style: TextStyle(fontSize: 12, color: daysBetween(d, today) == 0 ? tt.primary : tt.text)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget row(Habit h) {
      final stats = habitStats(h, s.checkinsOf(h.id), now);
      return InkWell(
        onTap: () => _open(context, h.id),
        onSecondaryTapUp: (d) => unawaited(_habitMenu(context, h, d.globalPosition)),
        onLongPress: () => unawaited(_habitMenu(context, h, Offset(MediaQuery.sizeOf(context).width / 2, 200))),
        child: Container(
          color: _selected == h.id ? tt.selected : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              HabitIcon(habit: h),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tt.text, fontSize: TtText.body),
                    ),
                    Text(
                      t.habitSummary(stats.totalDays, stats.streak),
                      style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                    ),
                  ],
                ),
              ),
              if (filterDay != null)
                HabitDot(habit: h, checkin: _checkinOn(s, h.id, filterDay), day: filterDay)
              else if (!narrow)
                for (final d in week)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: HabitDot(habit: h, checkin: _checkinOn(s, h.id, d), day: d),
                  )
              else
                HabitDot(habit: h, checkin: _checkinOn(s, h.id, today), day: today),
            ],
          ),
        ),
      );
    }

    final List<Widget> body;
    if (_archived) {
      body = shown.isEmpty
          ? [_Empty(title: t.habitArchivedEmptyTitle, body: t.habitArchivedEmptyBody)]
          : [
              for (final h in shown)
                ListTile(
                  leading: HabitIcon(habit: h),
                  title: Text(h.name),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      final repo = ref.read(repositoryProvider);
                      if (v == 'restore') {
                        await repo.archiveHabit(h.id, archived: false);
                        if (context.mounted) showToast(context, t.toastRestoredHabit);
                      } else {
                        await repo.deleteHabit(h.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'restore', height: 36, child: Text(t.habitRestore)),
                      PopupMenuItem(value: 'delete', height: 36, child: Text(t.habitDelete)),
                    ],
                  ),
                ),
            ];
    } else if (habits.isEmpty) {
      body = [_Empty(title: t.habitEmptyTitle, body: t.habitEmptyBody)];
    } else if (shown.isEmpty) {
      body = [_Empty(title: t.habitFreeDay, body: '')];
    } else {
      final sections = [
        ...habitSections,
        ...{for (final h in shown) h.section}.where((x) => !habitSections.contains(x)),
      ];
      Widget card(Habit h) {
        final stats = habitStats(h, s.checkinsOf(h.id), now);
        final day = filterDay ?? today;
        return SizedBox(
          width: 200,
          child: Material(
            color: tt.fieldFill,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _open(context, h.id),
              onSecondaryTapUp: (d) => unawaited(_habitMenu(context, h, d.globalPosition)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HabitIcon(habit: h),
                        const Spacer(),
                        HabitDot(habit: h, checkin: _checkinOn(s, h.id, day), day: day, size: 30),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tt.text, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      t.habitSummary(stats.totalDays, stats.streak),
                      style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      body = _cards
          ? [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(spacing: 12, runSpacing: 12, children: [for (final h in shown) card(h)]),
              ),
            ]
          : [
              for (final section in sections)
                if (shown.any((h) => h.section == section)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: Text(
                      habitSectionLabel(t, section),
                      style: TextStyle(fontWeight: FontWeight.w600, color: tt.textSecondary, fontSize: TtText.small),
                    ),
                  ),
                  for (final h in shown.where((h) => h.section == section)) row(h),
                ],
            ];
    }

    final page = Container(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (!_archived) strip,
          if (filterDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(label: Text('${filterDay.day} ${dates.monthShort(filterDay)}'), onDeleted: () => setState(() => _filterDay = null)),
              ),
            ),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 24), children: body),
          ),
        ],
      ),
    );
    final wide = MediaQuery.sizeOf(context).width >= _panelBreakpoint;
    final selected = _selected;
    return ModuleScaffold(
      module: AppModule.habit,
      child: !wide || _archived
          ? page
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: page),
                // The opened habit, or a quiet placeholder, like the task detail column.
                Container(
                  width: 440,
                  decoration: BoxDecoration(
                    color: tt.screen,
                    border: Border(left: BorderSide(color: tt.divider)),
                  ),
                  child: selected == null || !s.habits.any((x) => x.id == selected)
                      ? Center(child: Icon(Icons.track_changes, size: 96, color: tt.divider))
                      : _HabitDetail(key: ValueKey(selected), habitId: selected, onClose: () => setState(() => _selected = null)),
                ),
              ],
            ),
    );
  }

  /// Right click on a habit: Editar · Arquivar · Começar o foco · Deletar.
  Future<void> _habitMenu(BuildContext context, Habit h, Offset at) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'edit', height: 36, child: Text(t.countdownEdit)),
        PopupMenuItem(value: 'archive', height: 36, child: Text(t.habitArchive)),
        PopupMenuItem(value: 'focus', height: 36, child: Text(t.focusStartFocus)),
        PopupMenuItem(value: 'delete', height: 36, child: Text(t.habitDelete)),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'focus':
        // A Pomo linked to the habit.
        ref.read(focusProvider.notifier).start(mode: FocusMode.pomo, taskId: '$habitFocusPrefix${h.id}');
        context.go(Routes.focus);
      case 'edit':
        await showHabitForm(context, editing: h);
      case 'archive':
        await repo.archiveHabit(h.id, archived: true);
        if (context.mounted) showToast(context, t.toastArchived);
      case 'delete':
        await repo.deleteHabit(h.id);
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, size: 72, color: tt.divider),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: tt.textSecondary)),
          if (body.isNotEmpty)
            Text(
              body,
              style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
            ),
        ],
      ),
    );
  }
}

/// Habit detail: Registros mensais · Total de check-ins · Taxa de check-in mensal ·
/// Sequência atual, the month with a dot per day and the month's logs.
Future<void> showHabitDetail(BuildContext context, String habitId) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    child: SizedBox(
      width: 520,
      height: 620,
      child: _HabitDetail(habitId: habitId, onClose: () => Navigator.pop(context)),
    ),
  ),
);

class _HabitDetail extends ConsumerStatefulWidget {
  const _HabitDetail({super.key, required this.habitId, required this.onClose});

  final String habitId;

  /// The ✕: closes the dialog, or the side panel on wide screens.
  final VoidCallback onClose;

  @override
  ConsumerState<_HabitDetail> createState() => _HabitDetailState();
}

class _HabitDetailState extends ConsumerState<_HabitDetail> {
  late DateTime _month = DateTime(ref.read(clockProvider).now().year, ref.read(clockProvider).now().month);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final h = s.habits.where((x) => x.id == widget.habitId).firstOrNull;
    if (h == null) return const SizedBox.shrink();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final stats = habitStats(h, s.checkinsOf(h.id), now);
    final first = _month;
    final start = startOfWeek(first);
    final logs = s.checkinsOf(h.id).where((c) {
      final d = habitDay(c.day);
      return d.year == _month.year && d.month == _month.month && (c.note.isNotEmpty || c.mood != null);
    }).toList()..sort((a, b) => a.day.compareTo(b.day));
    const moods = ['😞', '🙁', '😐', '🙂', '😄'];

    Widget card(String label, String value) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, maxLines: 2, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            HabitIcon(habit: h),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                  if (h.motto.isNotEmpty)
                    Text(
                      h.motto,
                      style: TextStyle(fontSize: TtText.small, fontStyle: FontStyle.italic, color: tt.textTertiary),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.countdownEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => unawaited(showHabitForm(context, editing: h)),
            ),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: widget.onClose),
          ],
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card(t.habitMonthRecords, t.habitDaysValue(stats.monthDays)),
              card(t.habitTotalCheckins, t.habitDaysValue(stats.totalDays)),
              card(t.habitMonthRate, '${stats.monthRate}%'),
              card(t.habitStreak, t.habitDaysValue(stats.streak)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                dates.monthTitle(_month),
                style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ],
        ),
        for (var week = 0; week < 6; week++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = DateTime(start.year, start.month, start.day + week * 7 + d);
                        if (day.month != _month.month) return const SizedBox(height: 30);
                        return Center(
                          child: Column(
                            children: [
                              Text('${day.day}', style: TextStyle(fontSize: 10, color: tt.textTertiary)),
                              HabitDot(habit: h, checkin: _checkinOn(s, h.id, day), day: day, size: 22),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          t.habitMonthLog(dates.monthLong(_month)),
          style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
        ),
        const SizedBox(height: 6),
        if (logs.isEmpty)
          Text(
            t.habitMonthLogEmpty,
            style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
          ),
        for (final c in logs)
          ListTile(
            dense: true,
            leading: Text(c.mood == null ? '📝' : moods[c.mood! - 1], style: const TextStyle(fontSize: 20)),
            title: Text(c.note.isEmpty ? '' : c.note),
            subtitle: Text('${habitDay(c.day).day} ${dates.monthShort(habitDay(c.day))}'),
            onTap: () => unawaited(showHabitLog(context, ref, h, habitDay(c.day), c)),
          ),
        // Heatmap of the last year, a column per week.
        const SizedBox(height: 12),
        Text(
          t.habitYearHeatmap,
          style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
        ),
        const SizedBox(height: 6),
        _YearHeatmap(habit: h, checkinOn: (day) => _checkinOn(s, h.id, day), today: startOfDay(ref.read(clockProvider).now())),
      ],
    );
  }
}

/// A year of check-ins: 53 columns of weeks, a square per day, stronger when done.
class _YearHeatmap extends StatelessWidget {
  const _YearHeatmap({required this.habit, required this.checkinOn, required this.today});

  final Habit habit;
  final HabitCheckin? Function(DateTime day) checkinOn;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final first = startOfWeek(today).subtract(const Duration(days: 52 * 7));
    Color colorOf(DateTime day) {
      if (day.isAfter(today)) return Colors.transparent;
      return switch (habitDayState(habit, checkinOn(day), day)) {
        HabitDayState.done => tt.primary,
        HabitDayState.partial => tt.primary.withValues(alpha: 0.45),
        HabitDayState.failed => tt.palette.priorityHigh.withValues(alpha: 0.55),
        HabitDayState.skipped || HabitDayState.open || HabitDayState.notRequired => tt.fieldFill,
      };
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var week = 0; week < 53; week++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    if (DateTime(first.year, first.month, first.day + week * 7 + d) case final day)
                      Tooltip(
                        message: DateLabels.numeric(day),
                        child: Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(color: colorOf(day), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
