import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/calendar.dart';
import '../../domain/calendar_insights.dart';
import '../../domain/color_labels.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';

/// How the time is split: by color label (Google's "By label"), list, tag or kind ("By type").
enum InsightsGroup { label, list, tag, kind }

/// A slice ready to draw: its name, color and time.
typedef InsightRow = ({String name, Color color, Duration time});

/// The breakdown of [entries] for the period, named and colored for the chosen [group].
({List<InsightRow> rows, List<Duration> perDay, Duration total}) insightRows(
  BuildContext context,
  Snapshot s,
  List<ColorLabel> colorLabels,
  List<CalendarEntry> entries,
  DateTime from,
  int days,
  InsightsGroup group,
) {
  final t = AppLocalizations.of(context);
  final tt = context.tt;
  final labels = Labels(t);
  final isTask = {CalendarEntryKind.task, CalendarEntryKind.checklistItem};
  final paletteNames = t.eventColorNames.split(',');
  String? keyOf(CalendarEntry e) => switch (group) {
    InsightsGroup.label => isTask.contains(e.kind) && e.task != null ? normalizeColor(e.task!.color ?? '') : null,
    InsightsGroup.list => isTask.contains(e.kind) ? e.task?.listId : null,
    InsightsGroup.tag => isTask.contains(e.kind) && e.task != null ? (s.tagsOf(e.task!.id).firstOrNull?.id ?? '') : null,
    InsightsGroup.kind => switch (e.kind) {
      CalendarEntryKind.task || CalendarEntryKind.checklistItem => 'task',
      CalendarEntryKind.focus => 'focus',
      CalendarEntryKind.event => 'event',
      _ => null,
    },
  };
  final r = timeInsights(entries, from, days, keyOf);
  InsightRow row(InsightSlice slice) {
    switch (group) {
      case InsightsGroup.label:
        return slice.key.isEmpty
            ? (name: t.insightsNoLabel, color: tt.textTertiary, time: slice.time)
            : (
                name: colorName(slice.key, colorLabels, paletteNames, custom: t.colorCustom),
                color: parseHexColor(slice.key) ?? tt.primary,
                time: slice.time,
              );
      case InsightsGroup.list:
        final list = s.listById[slice.key];
        return (name: list == null ? t.untitled : labels.listName(list), color: parseHexColor(list?.color) ?? tt.primary, time: slice.time);
      case InsightsGroup.tag:
        final tag = s.tags.where((x) => x.id == slice.key).firstOrNull;
        return (name: tag?.name ?? t.insightsNoTag, color: parseHexColor(tag?.color) ?? tt.textTertiary, time: slice.time);
      case InsightsGroup.kind:
        return switch (slice.key) {
          'focus' => (name: t.navFocus, color: tt.textTertiary, time: slice.time),
          'event' => (name: t.subscriptionsTitle, color: tt.palette.priorityMedium, time: slice.time),
          _ => (name: t.insightsTasks, color: tt.primary, time: slice.time),
        };
    }
  }

  // "Sem rótulo" goes last, after the labels.
  final slices = group == InsightsGroup.label ? [...r.slices.where((x) => x.key.isNotEmpty), ...r.slices.where((x) => x.key.isEmpty)] : r.slices;
  return (rows: [for (final slice in slices) row(slice)], perDay: r.perDay, total: r.total);
}

/// Google Calendar's "Time Insights" panel on the right: the
/// period, "Detalhamento do tempo" (Por lista | Por etiqueta | Por tipo) as a donut with the total and
/// the legend, and the hours of each day.
class CalendarInsightsPanel extends ConsumerStatefulWidget {
  const CalendarInsightsPanel({
    super.key,
    required this.entries,
    required this.from,
    required this.days,
    required this.period,
    required this.onClose,
    this.width = defaultWidth,
  });

  final List<CalendarEntry> entries;
  final DateTime from;
  final int days;

  /// The period's title ("Setembro 2026", "20 – 26 set").
  final String period;
  final VoidCallback onClose;

  /// Null fills the screen (phones).
  final double? width;

  static const defaultWidth = 340.0;

  @override
  ConsumerState<CalendarInsightsPanel> createState() => _CalendarInsightsPanelState();
}

class _CalendarInsightsPanelState extends ConsumerState<CalendarInsightsPanel> {
  InsightsGroup _group = InsightsGroup.label;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final colorLabels = (ref.watch(preferencesProvider).value ?? Preferences.defaults).colorLabels;
    final data = insightRows(context, s, colorLabels, widget.entries, widget.from, widget.days, _group);
    final maxDay = data.perDay.fold(Duration.zero, (a, b) => b > a ? b : a);

    Widget card(String title, List<Widget> children) => Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: tt.screen,
        border: widget.width == null ? null : Border(left: BorderSide(color: tt.divider)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.period.toUpperCase(),
                      style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: tt.textTertiary),
                    ),
                    Text(
                      t.insightsTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tt.text),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.actionClose,
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: widget.onClose,
              ),
            ],
          ),
          card(t.insightsBreakdown, [
            SegmentedButton<InsightsGroup>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(
                  value: InsightsGroup.label,
                  label: Text(t.insightsByLabel, style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: InsightsGroup.list,
                  label: Text(t.insightsByList, style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: InsightsGroup.tag,
                  label: Text(t.insightsByTag, style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: InsightsGroup.kind,
                  label: Text(t.insightsByKind, style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_group},
              onSelectionChanged: (v) => setState(() => _group = v.first),
            ),
            const SizedBox(height: 14),
            if (data.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  t.insightsEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tt.textTertiary),
                ),
              )
            else ...[
              SizedBox(
                height: 170,
                child: CustomPaint(
                  painter: _DonutPainter([for (final r in data.rows) (color: r.color, time: r.time)], track: tt.divider),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          insightHours(data.total),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: tt.text),
                        ),
                        Text(
                          t.insightsTotal,
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final r in data.rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: tt.text),
                        ),
                      ),
                      Text(
                        insightHours(r.time),
                        style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ]),
          // A year has too many days for one bar each.
          if (widget.days <= 31)
            card(t.insightsPerDay, [
              for (var i = 0; i < widget.days; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${dates.weekdayShort(DateTime(widget.from.year, widget.from.month, widget.from.day + i))} ${DateTime(widget.from.year, widget.from.month, widget.from.day + i).day}',
                          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) => Container(
                            height: 8,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(color: tt.text.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(4)),
                            child: Container(
                              width: data.perDay[i] == Duration.zero ? 0 : math.max(8, box.maxWidth * data.perDay[i].inMinutes / maxDay.inMinutes),
                              decoration: BoxDecoration(color: tt.primary, borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          insightHours(data.perDay[i]),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
        ],
      ),
    );
  }
}

/// The donut: one arc per slice, a little gap between them, over a faint track.
class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, {required this.track});

  final List<({Color color, Duration time})> slices;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final total = slices.fold<int>(0, (a, s) => a + s.time.inMinutes);
    if (total == 0) return;
    const gap = 0.03;
    var angle = -math.pi / 2;
    for (final s in slices) {
      final sweep = math.pi * 2 * s.time.inMinutes / total;
      canvas.drawArc(
        rect,
        angle + (slices.length > 1 ? gap / 2 : 0),
        math.max(0.01, sweep - (slices.length > 1 ? gap : 0)),
        false,
        paint..color = s.color,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices || old.track != track;
}

/// The "Time Insights" part of the left panel, as Google's: the period, a bar split by color label
/// and, when the pointer is on it (or it is tapped), a card with each label's hours; "Mais insights".
class CalendarInsightsSummary extends ConsumerStatefulWidget {
  const CalendarInsightsSummary({
    super.key,
    required this.entries,
    required this.from,
    required this.days,
    required this.period,
    required this.onMore,
  });

  final List<CalendarEntry> entries;
  final DateTime from;
  final int days;
  final String period;
  final VoidCallback onMore;

  @override
  ConsumerState<CalendarInsightsSummary> createState() => _CalendarInsightsSummaryState();
}

class _CalendarInsightsSummaryState extends ConsumerState<CalendarInsightsSummary> {
  final _card = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final colorLabels = (ref.watch(preferencesProvider).value ?? Preferences.defaults).colorLabels;
    final data = insightRows(context, s, colorLabels, widget.entries, widget.from, widget.days, InsightsGroup.label);

    final bar = SizedBox(
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: data.rows.isEmpty
            ? ColoredBox(color: tt.text.withValues(alpha: 0.07))
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, r) in data.rows.indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: math.max(1, r.time.inMinutes),
                      child: ColoredBox(color: r.color),
                    ),
                  ],
                ],
              ),
      ),
    );

    // The card under the bar: every label with its hours.
    Widget card(BuildContext context) => CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      offset: const Offset(-4, 6),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in data.rows)
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: TtText.body, color: tt.text),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            insightHours(r.time),
                            style: TextStyle(fontSize: TtText.body, color: tt.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.period.toUpperCase(),
          style: TextStyle(fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w600, color: tt.textSecondary),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _card,
            overlayChildBuilder: card,
            child: MouseRegion(
              onEnter: (_) {
                if (data.rows.isNotEmpty) _card.show();
              },
              onExit: (_) => _card.hide(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: data.rows.isEmpty ? null : _card.toggle,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: bar),
              ),
            ),
          ),
        ),
        if (data.rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              t.insightsEmpty,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: tt.primary,
              side: BorderSide(color: tt.divider),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: widget.onMore,
            child: Text(t.insightsMore),
          ),
        ),
      ],
    );
  }
}
