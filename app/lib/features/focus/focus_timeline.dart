import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/focus_controller.dart';
import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import 'focus_page.dart' show focusRecordsProvider;
import 'focus_timers.dart';

const _hourHeight = 48.0;
const _labelWidth = 44.0;

/// Right side of the Focus screen during a session: the linked item and a
/// timeline of the day around now, with the current time in red, the focus sessions in green and the
/// tasks with a time.
class FocusSessionPanel extends ConsumerWidget {
  const FocusSessionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final focus = ref.watch(focusProvider);
    ref.watch(focusClockProvider);
    final now = ref.read(clockProvider).now();
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final records = ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[];
    final linked = focusLinkName(t, s, focus.taskId);
    final today = startOfDay(now);
    final tomorrow = DateTime(today.year, today.month, today.day + 1);

    // Blocks of today: past sessions, the running one, and the tasks with a time.
    final sessions = <(DateTime, DateTime)>[
      for (final r in records)
        if (r.deletedAt == null && r.endedAt.toLocal().isAfter(today) && r.startedAt.toLocal().isBefore(tomorrow))
          (r.startedAt.toLocal(), r.endedAt.toLocal()),
      if (focus.startedAt case final start? when focus.phase == FocusPhase.focusing || focus.phase == FocusPhase.paused) (start, now),
    ];
    final tasks = <(DateTime, DateTime, String)>[
      for (final task in s.tasks)
        if (task.deletedAt == null && task.status == TaskStatus.open && !task.isAllDay)
          if ((task.startLocal, task.endLocal) case (final start?, final end?) when !end.isBefore(today) && start.isBefore(tomorrow))
            (start, task.hasDuration ? end : start.add(const Duration(minutes: 30)), task.title.isEmpty ? t.untitled : task.title),
    ];

    final sessionStart = focus.startedAt;
    final first = math.max(0, math.min(now.hour - 2, sessionStart != null && !sessionStart.isBefore(today) ? sessionStart.hour : 24));
    final last = math.min(24, math.max(now.hour + 3, first + 1));
    final height = (last - first) * _hourHeight;
    double y(DateTime at) {
      final minutes = at.isBefore(today) ? 0 : (at.isAfter(tomorrow) ? 24 * 60 : at.hour * 60 + at.minute + at.second / 60);
      return ((minutes - first * 60) / 60 * _hourHeight).clamp(0, height).toDouble();
    }

    Widget block(DateTime start, DateTime end, Color color, {String? label}) {
      final top = y(start), bottom = y(end);
      if (bottom <= 0 || top >= height) return const SizedBox.shrink();
      return Positioned(
        left: _labelWidth + 4,
        right: 0,
        top: top,
        height: math.max(bottom - top, label == null ? 3 : 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          child: label == null
              ? null
              : Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: tt.text),
                ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.adjust, size: 18, color: linked == null ? tt.textTertiary : tt.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  linked ?? t.focusNoTask,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: linked == null ? tt.textTertiary : tt.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var h = first; h <= last; h++) ...[
                  Positioned(
                    left: _labelWidth + 4,
                    right: 0,
                    top: (h - first) * _hourHeight,
                    child: Container(height: 1, color: tt.divider),
                  ),
                  if (h < 24)
                    Positioned(
                      left: 0,
                      width: _labelWidth,
                      top: (h - first) * _hourHeight - 7,
                      child: Text(DateLabels.time(DateTime(2000, 1, 1, h)), style: TextStyle(fontSize: 10, color: tt.textTertiary)),
                    ),
                ],
                for (final (start, end, title) in tasks) block(start, end, tt.primary.withValues(alpha: 0.25), label: title),
                for (final (start, end) in sessions) block(start, end, tt.palette.green.withValues(alpha: 0.6)),
                Positioned(
                  left: _labelWidth,
                  right: 0,
                  top: y(now) - 1,
                  child: Container(height: 2, color: tt.palette.priorityHigh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
