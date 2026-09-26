import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/focus_controller.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../habits/habit_widgets.dart';
import '../search/task_link_picker.dart';
import 'focus_page.dart' show showFocusRecordForm;
import 'focus_records.dart' show showTimerDetail;

/// Name of what a focus is linked to: the task's title or the habit's name.
String? focusLinkName(AppLocalizations t, Snapshot s, String? link) {
  if (link == null) return null;
  final habitId = focusHabitId(link);
  if (habitId != null) return s.habits.where((h) => h.id == habitId).firstOrNull?.name;
  final task = s.taskById[link];
  return task == null ? null : (task.title.isEmpty ? t.untitled : task.title);
}

/// "Foco": link to a task or a habit. Returns the link, '' to remove it, or null.
Future<String?> pickFocusLink(BuildContext context, WidgetRef ref, {String? current}) async {
  final t = AppLocalizations.of(context);
  final habits = [
    for (final h in (ref.read(snapshotProvider).value ?? Snapshot.empty()).habits)
      if (h.deletedAt == null && h.archivedAt == null) h,
  ];
  final choice = await showDialog<Object>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.focusLink, style: const TextStyle(fontSize: 15)),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'task'),
          child: Row(children: [const Icon(Icons.check_box_outlined, size: 18), const SizedBox(width: 10), Text(t.focusLinkTask)]),
        ),
        if (habits.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: Text(
              t.navHabit,
              style: TextStyle(fontSize: TtText.small, color: context.tt.textTertiary),
            ),
          ),
          for (final h in habits)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, h),
              child: Row(
                children: [
                  HabitIcon(habit: h, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(h.name)),
                ],
              ),
            ),
        ],
        if (current != null) ...[const Divider(), SimpleDialogOption(onPressed: () => Navigator.pop(context, ''), child: Text(t.focusUnlink))],
      ],
    ),
  );
  if (!context.mounted) return null;
  return switch (choice) {
    'task' => (await pickTaskToLink(context))?.id,
    final Habit h => '$habitFocusPrefix${h.id}',
    final String s => s,
    _ => null,
  };
}

/// "Adicionar temporizador." (the "+" of the Focus header) or editing one.
Future<void> editFocusTimer(BuildContext context, WidgetRef ref, {FocusTimer? editing}) async {
  final saved = await showDialog<FocusTimer>(
    context: context,
    builder: (_) => _TimerForm(editing: editing),
  );
  if (saved == null) return;
  final timers = (ref.read(preferencesProvider).value ?? Preferences.defaults).focusTimers;
  await ref.read(preferencesRepositoryProvider).setFocusTimers([
    for (final other in timers) other.id == saved.id ? saved : other,
    if (editing == null) saved,
  ]);
}

/// Deletes a timer, after asking (its focus records stay). [close] runs just before (the form closing
/// itself).
Future<void> deleteFocusTimer(BuildContext context, WidgetRef ref, FocusTimer timer, {VoidCallback? close}) async {
  final t = AppLocalizations.of(context);
  if (!await confirm(context, message: t.focusTimerDeleteConfirm(timer.name), confirmLabel: t.actionDelete)) return;
  if (!context.mounted) return;
  final prefs = ref.read(preferencesRepositoryProvider);
  final timers = (ref.read(preferencesProvider).value ?? Preferences.defaults).focusTimers;
  close?.call();
  await prefs.setFocusTimers([
    for (final other in timers)
      if (other.id != timer.id) other,
  ]);
}

/// The Focus screen once a timer exists: tabs Ativo / Arquivado and, per timer, its
/// icon, name, total focused with it and ▶.
class FocusTimerList extends ConsumerStatefulWidget {
  const FocusTimerList({super.key, required this.records, required this.onStart});

  final List<FocusRecord> records;

  /// After ▶: the page shows the clock.
  final VoidCallback onStart;

  @override
  ConsumerState<FocusTimerList> createState() => _FocusTimerListState();
}

class _FocusTimerListState extends ConsumerState<FocusTimerList> {
  bool _archived = false;

  Future<void> _save(List<FocusTimer> timers) => ref.read(preferencesRepositoryProvider).setFocusTimers(timers);

  Widget _tab(String label, bool archived) {
    final tt = context.tt;
    final selected = _archived == archived;
    return InkWell(
      onTap: () => setState(() => _archived = archived),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? tt.primary : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: selected ? tt.text : tt.textTertiary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final all = (ref.watch(preferencesProvider).value ?? Preferences.defaults).focusTimers;
    final timers = all.where((x) => x.archived == _archived).toList();
    final idle = ref.watch(focusProvider).phase == FocusPhase.idle;
    Duration total(String id) =>
        Duration(seconds: widget.records.where((r) => r.timerId == id && r.deletedAt == null).fold(0, (sum, r) => sum + r.seconds));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [_tab(t.habitActive, false), _tab(t.habitArchived, true)]),
        const SizedBox(height: 8),
        if (timers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _archived ? t.focusTimersArchivedEmpty : t.focusTimersEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: tt.textTertiary),
            ),
          ),
        for (final timer in timers)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(8)),
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                // The timer's detail: its days, totals, week and records.
                onTap: () => unawaited(showTimerDetail(context, timer)),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: tt.primary.withValues(alpha: 0.15),
                  child: Icon(timer.mode == FocusMode.pomo ? Icons.timer_outlined : Icons.av_timer, size: 18, color: tt.primary),
                ),
                title: Text(timer.name, style: TextStyle(color: tt.text)),
                subtitle: Text(
                  [
                    if (timer.mode == FocusMode.pomo) t.focusMinutesValue(timer.minutes) else t.focusTabStopwatch,
                    ?focusLinkName(t, s, timer.link),
                  ].join(' · '),
                  style: TextStyle(fontSize: 11, color: tt.textTertiary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      focusDuration(total(timer.id), hours: t.focusHours, minutes: t.focusMins),
                      style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                    ),
                    if (!timer.archived)
                      IconButton(
                        tooltip: t.focusStart,
                        icon: Icon(Icons.play_circle_outline, color: idle ? tt.primary : tt.textTertiary),
                        onPressed: idle
                            ? () {
                                ref.read(focusProvider.notifier).startTimer(timer);
                                widget.onStart();
                              }
                            : null,
                      ),
                    PopupMenuButton<String>(
                      tooltip: '',
                      icon: Icon(Icons.more_horiz, size: 18, color: tt.textTertiary),
                      onSelected: (v) async {
                        switch (v) {
                          case 'edit':
                            await editFocusTimer(context, ref, editing: timer);
                          case 'record':
                            await showFocusRecordForm(context, taskId: timer.link, timerId: timer.id);
                          case 'archive':
                            await _save([for (final other in all) other.id == timer.id ? other.withArchived(!timer.archived) : other]);
                          default:
                            await deleteFocusTimer(context, ref, timer);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', height: 36, child: Text(t.actionEdit)),
                        PopupMenuItem(value: 'record', height: 36, child: Text(t.focusTimerAddRecord)),
                        PopupMenuItem(value: 'archive', height: 36, child: Text(timer.archived ? t.menuRestore : t.actionArchive)),
                        PopupMenuItem(value: 'delete', height: 36, child: Text(t.actionDelete)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimerForm extends ConsumerStatefulWidget {
  const _TimerForm({this.editing});

  final FocusTimer? editing;

  @override
  ConsumerState<_TimerForm> createState() => _TimerFormState();
}

class _TimerFormState extends ConsumerState<_TimerForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late FocusMode _mode = widget.editing?.mode ?? FocusMode.pomo;
  late int _minutes = widget.editing?.minutes ?? 25;
  late String? _link = widget.editing?.link;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final linkName = focusLinkName(t, s, _link);
    return AlertDialog(
      title: Text(widget.editing == null ? t.focusTimerAdd : t.focusTimerEdit, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: t.focusTimerName, filled: true, fillColor: tt.fieldFill, border: InputBorder.none),
            ),
            const SizedBox(height: 12),
            SegmentedButton<FocusMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: FocusMode.pomo, label: Text(t.focusTabPomo)),
                ButtonSegment(value: FocusMode.stopwatch, label: Text(t.focusTabStopwatch)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            if (_mode == FocusMode.pomo)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.focusPomoLength),
                trailing: DropdownButton<int>(
                  value: _minutes,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final m in {5, 10, 15, 20, 25, 30, 45, 50, 60, 90, 120, _minutes}.toList()..sort())
                      DropdownMenuItem(value: m, child: Text(t.focusMinutesValue(m))),
                  ],
                  onChanged: (v) => setState(() => _minutes = v ?? _minutes),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.adjust, size: 18),
              title: Text(linkName ?? t.focusLink, style: TextStyle(color: linkName == null ? tt.textSecondary : tt.text)),
              onTap: () async {
                final picked = await pickFocusLink(context, ref, current: _link);
                if (picked != null) setState(() => _link = picked.isEmpty ? null : picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        if (widget.editing case final timer?)
          IconButton(
            tooltip: t.actionDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () => unawaited(deleteFocusTimer(context, ref, timer, close: () => Navigator.pop(context))),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  FocusTimer(
                    id: widget.editing?.id ?? newId(),
                    name: _name.text.trim(),
                    mode: _mode,
                    minutes: _minutes,
                    link: _link,
                    archived: widget.editing?.archived ?? false,
                  ),
                ),
          child: Text(t.actionSave),
        ),
      ],
    );
  }
}
