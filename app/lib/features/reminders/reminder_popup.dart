import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../app/routes.dart';
import '../../app/focus_controller.dart';
import '../../app/reminders.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/reminder_plan.dart';
import '../../domain/snooze.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';

/// Popups of reminders that fired while the app is open: the date, the title, ✕, "Adiar"
/// with its options and "Concluído". Bottom-right on desktop, bottom on narrow screens.
///
/// Lives in `MaterialApp.builder`, above the Navigator: nothing here may need an Overlay (tooltips,
/// menus), and dialogs use [navigatorContext].
class ReminderPopups extends ConsumerWidget {
  const ReminderPopups({super.key, required this.onOpen, required this.navigatorContext});

  final void Function(String taskId) onOpen;
  final BuildContext? Function() navigatorContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fired = ref.watch(firedRemindersProvider);
    if (fired.isEmpty) return const SizedBox.shrink();
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final cards = [
      for (final r in fired.reversed.take(3))
        _ReminderCard(key: ValueKey('${r.id}@${r.at}'), reminder: r, onOpen: onOpen, navigatorContext: navigatorContext),
    ];
    return Positioned(
      right: 16,
      left: narrow ? 16 : null,
      bottom: 16,
      child: SafeArea(
        child: SizedBox(
          width: narrow ? null : 340,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: cards),
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerStatefulWidget {
  const _ReminderCard({super.key, required this.reminder, required this.onOpen, required this.navigatorContext});

  final PlannedReminder reminder;
  final void Function(String taskId) onOpen;
  final BuildContext? Function() navigatorContext;

  @override
  ConsumerState<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<_ReminderCard> {
  bool _snoozeOpen = false;

  PlannedReminder get _r => widget.reminder;

  void _close() => ref.read(firedRemindersProvider.notifier).remove(_r);

  Future<void> _complete() async {
    _close();
    final repo = ref.read(repositoryProvider);
    final itemId = _r.itemId;
    if (itemId != null) {
      await repo.setChecklistItemCompleted(itemId, completed: true);
    } else if ((await repo.task(_r.taskId)).deletedAt == null) {
      await repo.complete(_r.taskId);
    }
  }

  Future<void> _snooze(DateTime until) async {
    _close();
    await ref.read(repositoryProvider).snooze(_r.taskId, until);
  }

  Future<void> _customSnooze() async {
    final context = widget.navigatorContext();
    if (context == null) return;
    final now = ref.read(clockProvider).now();
    final picked = await showTtDatePicker(
      context,
      initial: DateSelection(dueDate: now.add(const Duration(hours: 1)), isAllDay: false),
      now: now,
    );
    final date = picked?.dueDate;
    if (date == null) return;
    await _snooze(picked!.isAllDay ? DateTime(date.year, date.month, date.day, tomorrowHour) : date);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final now = ref.watch(clockProvider).now();
    final dateLabel = DateLabels(t).detailDate(_r.due, isAllDay: _r.isAllDay, today: startOfDay(now));
    final options = {
      SnoozeOption.minutes15: t.snooze15m,
      SnoozeOption.minutes30: t.snooze30m,
      SnoozeOption.hour1: t.snooze1h,
      SnoozeOption.hours3: t.snooze3h,
      SnoozeOption.tonight: t.snoozeTonight,
      SnoozeOption.tomorrow: t.snoozeTomorrow,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tt.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.alarm, size: 16, color: tt.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: TextStyle(fontSize: TtText.small, color: tt.primary),
                    ),
                  ),
                  // "Começar foco" on the task. No tooltip: the popups sit above the
                  // Navigator, where there is no Overlay.
                  if (!_r.taskId.contains(':'))
                    Semantics(
                      label: t.focusStartFocus,
                      button: true,
                      child: InkWell(
                        onTap: () {
                          _close();
                          ref.read(focusProvider.notifier).start(mode: FocusMode.pomo, taskId: _r.taskId);
                          final navigator = widget.navigatorContext();
                          if (navigator != null && navigator.mounted) GoRouter.of(navigator).go(Routes.focus);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.timer_outlined, size: 16, color: tt.textTertiary),
                        ),
                      ),
                    ),
                  Semantics(
                    label: t.reminderPopupDismiss,
                    button: true,
                    child: InkWell(
                      onTap: _close,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 16, color: tt.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  _close();
                  widget.onOpen(_r.taskId);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 8, 12),
                  child: Text(
                    _r.title.isEmpty ? t.untitled : _r.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tt.text),
                  ),
                ),
              ),
              if (_snoozeOpen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, right: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final o in options.entries)
                        if (snoozeTime(o.key, now) case final DateTime until)
                          ActionChip(label: Text(o.value), onPressed: () => unawaited(_snooze(until))),
                      ActionChip(label: Text(t.snoozeCustom), onPressed: () => unawaited(_customSnooze())),
                    ],
                  ),
                ),
              Row(
                children: [
                  // A checklist item can only be checked.
                  if (_r.itemId == null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _snoozeOpen = !_snoozeOpen),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Text(t.reminderPopupSnooze), Icon(_snoozeOpen ? Icons.expand_less : Icons.expand_more, size: 16)],
                        ),
                      ),
                    ),
                  if (_r.itemId == null) const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(onPressed: () => unawaited(_complete()), child: Text(t.reminderPopupDone)),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
