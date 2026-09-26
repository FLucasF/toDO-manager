import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/preferences_repository.dart';
import '../../domain/calendar.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../common/shell_widgets.dart';
import '../date_picker/month_calendar.dart';
import '../subscriptions/subscriptions.dart';

/// No list matches it: the list filter's way of saying "none" (an empty filter means all).
const _noList = '-';

/// Google Calendar's left panel: "+ Criar", the mini calendar,
/// "Meus calendários" (the lists, plus habits, countdowns and focus; the checkbox in their color shows
/// or hides them) and "Outros calendários" (the subscriptions, with "+").
class CalendarSidePanel extends ConsumerStatefulWidget {
  const CalendarSidePanel({super.key, required this.anchor, required this.onCreate, required this.onDay, this.insights});

  /// The date the calendar shows; the mini calendar follows it.
  final DateTime anchor;
  final VoidCallback onCreate;
  final ValueChanged<DateTime> onDay;

  /// The "Time Insights" section (Google shows it under the mini calendar).
  final Widget? insights;

  static const width = shellPanelWidth;

  @override
  ConsumerState<CalendarSidePanel> createState() => _CalendarSidePanelState();
}

class _CalendarSidePanelState extends ConsumerState<CalendarSidePanel> {
  /// The month browsed with ‹ ›; null follows the calendar.
  DateTime? _month;
  bool _mineOpen = true;
  bool _otherOpen = true;
  bool _insightsOpen = true;

  Future<void> _setOptions(CalendarOptions o) => ref.read(preferencesRepositoryProvider).setCalendarOptions(o);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final options = prefs.calendarOptions;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final today = startOfDay(ref.watch(nowProvider).value ?? ref.watch(clockProvider).now());
    final month = _month ?? DateTime(widget.anchor.year, widget.anchor.month);
    final lists = s.activeLists;
    bool listShown(String id) => options.listIds.isEmpty || options.listIds.contains(id);

    void setList(String id, {required bool shown}) {
      final visible = options.listIds.isEmpty ? {for (final l in lists) l.id} : {...options.listIds}
        ..remove(_noList);
      shown ? visible.add(id) : visible.remove(id);
      // All shown is the empty filter; none shown needs an id no list has.
      final filter = visible.length == lists.length ? <String>{} : (visible.isEmpty ? {_noList} : visible);
      unawaited(_setOptions(options.copyWith(listIds: filter)));
    }

    Widget section(String title, bool open, VoidCallback toggle, {Widget? action}) =>
        PanelSectionHeader(title: title, open: open, onToggle: toggle, action: action);

    return Container(
      width: CalendarSidePanel.width,
      color: tt.screen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // "+ Criar" (Create): a new task at the next hour, in the create popup.
          Align(
            alignment: Alignment.centerLeft,
            child: CreatePill(label: t.calendarCreate, onPressed: widget.onCreate),
          ),
          const SizedBox(height: 12),
          MonthCalendar(
            month: month,
            today: today,
            isSelected: (day) => day == widget.anchor,
            occurrences: const {},
            title: DateLabels(t).monthTitle(month),
            onPrevious: () => setState(() => _month = DateTime(month.year, month.month - 1)),
            onNext: () => setState(() => _month = DateTime(month.year, month.month + 1)),
            onToday: () {
              setState(() => _month = null);
              widget.onDay(today);
            },
            onPick: (day) {
              setState(() => _month = null);
              widget.onDay(day);
            },
          ),
          if (widget.insights case final insights?) ...[
            section(t.insightsTitle, _insightsOpen, () => setState(() => _insightsOpen = !_insightsOpen)),
            if (_insightsOpen) insights,
          ],
          section(t.calendarMyCalendars, _mineOpen, () => setState(() => _mineOpen = !_mineOpen)),
          if (_mineOpen) ...[
            for (final l in lists)
              PanelCheckRow(
                color: parseHexColor(l.color) ?? tt.primary,
                label: labels.listName(l),
                shown: listShown(l.id),
                onChanged: (v) => setList(l.id, shown: v),
                onOnly: () => unawaited(_setOptions(options.copyWith(listIds: lists.length == 1 ? <String>{} : {l.id}))),
              ),
            PanelCheckRow(
              color: tt.palette.priorityLow,
              label: t.navHabit,
              shown: options.showHabits,
              onChanged: (v) => unawaited(_setOptions(options.copyWith(showHabits: v))),
            ),
            PanelCheckRow(
              color: tt.palette.priorityMedium,
              label: t.navCountdown,
              shown: options.showCountdowns,
              onChanged: (v) => unawaited(_setOptions(options.copyWith(showCountdowns: v))),
            ),
            PanelCheckRow(
              color: tt.textSecondary,
              label: t.navFocus,
              shown: options.showFocus,
              onChanged: (v) => unawaited(_setOptions(options.copyWith(showFocus: v))),
            ),
            if (prefs.has(AppFeature.finance))
              PanelCheckRow(
                color: tt.palette.green,
                label: t.navFinance,
                shown: options.showFinance,
                onChanged: (v) => unawaited(_setOptions(options.copyWith(showFinance: v))),
              ),
          ],
          section(
            t.calendarOtherCalendars,
            _otherOpen,
            () => setState(() => _otherOpen = !_otherOpen),
            action: IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              tooltip: t.calendarAddOther,
              icon: Icon(Icons.add, color: tt.textSecondary),
              onPressed: () => unawaited(addUrlSubscription(context, ref)),
            ),
          ),
          if (_otherOpen)
            for (final sub in prefs.subscriptions)
              PanelCheckRow(
                color: subscriptionColor(context, ref, sub.id),
                label: sub.name,
                shown: sub.visible,
                onChanged: (v) => unawaited(setSubscriptionVisible(ref, sub, visible: v)),
              ),
        ],
      ),
    );
  }
}
