import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'focus_records.dart';
import 'focus_timeline.dart';
import 'focus_timers.dart';
import '../../app/focus_controller.dart';
import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../date_picker/date_picker.dart';
import '../search/task_link_picker.dart';
import '../shell/app_shell.dart';

final focusRecordsProvider = StreamProvider<List<FocusRecord>>((ref) => ref.watch(repositoryProvider).watchFocusRecords());

String _clock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  return h > 0 ? '$h:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}' : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
}

String _duration(AppLocalizations t, Duration d) => focusDuration(d, hours: t.focusHours, minutes: t.focusMins);

String pomoSoundLabel(AppLocalizations t, PomoSound sound) => switch (sound) {
  PomoSound.standard => t.focusSoundStandard,
  PomoSound.alarm => t.focusSoundAlarm,
  PomoSound.reminder => t.focusSoundReminder,
  PomoSound.message => t.focusSoundMessage,
  PomoSound.silent => t.focusSoundSilent,
};

/// "Configurações de foco", also opened from Settings → Funcionalidades.
Future<void> showFocusSettings(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  var s = ref.read(preferencesProvider).value?.focus ?? const FocusSettings();
  final saved = await showDialog<FocusSettings>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void set(FocusSettings next) => setState(() => s = next);
        Widget minutes(String label, int value, FocusSettings Function(int) next, {int min = 1}) => ListTile(
          dense: true,
          title: Text(label),
          trailing: DropdownButton<int>(
            value: value,
            items: [
              for (final m in {min, 5, 10, 15, 20, 25, 30, 45, 50, 60, 90, value}.toList()..sort())
                if (m >= min) DropdownMenuItem(value: m, child: Text(t.focusMinutesValue(m))),
            ],
            onChanged: (v) => set(next(v ?? value)),
          ),
        );
        return AlertDialog(
          scrollable: true,
          title: Text(t.focusSettings, style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                minutes(t.focusPomoLength, s.pomoMinutes, (v) => s.copyWith(pomoMinutes: v), min: 5),
                minutes(t.focusShortBreakLength, s.shortBreakMinutes, (v) => s.copyWith(shortBreakMinutes: v)),
                minutes(t.focusLongBreakLength, s.longBreakMinutes, (v) => s.copyWith(longBreakMinutes: v)),
                ListTile(
                  dense: true,
                  title: Text(t.focusLongEvery),
                  trailing: DropdownButton<int>(
                    value: s.pomosBeforeLongBreak,
                    items: [for (var n = 2; n <= 8; n++) DropdownMenuItem(value: n, child: Text('$n'))],
                    onChanged: (v) => set(s.copyWith(pomosBeforeLongBreak: v ?? 4)),
                  ),
                ),
                // Desktop: the window title plays the part of the browser tab (phones have no title).
                if (defaultTargetPlatform != TargetPlatform.android)
                  SwitchListTile(
                    dense: true,
                    title: Text(t.focusTimeInTitle),
                    value: s.timeInTitle,
                    onChanged: (v) => set(s.copyWith(timeInTitle: v)),
                  ),
                SwitchListTile(
                  dense: true,
                  title: Text(t.focusAutoPomo),
                  value: s.autoStartPomo,
                  onChanged: (v) => set(s.copyWith(autoStartPomo: v)),
                ),
                SwitchListTile(
                  dense: true,
                  title: Text(t.focusAutoBreak),
                  value: s.autoStartBreak,
                  onChanged: (v) => set(s.copyWith(autoStartBreak: v)),
                ),
                // "Som do Pomo": the sound of the end-of-Pomo notification.
                ListTile(
                  dense: true,
                  title: Text(t.focusSound),
                  trailing: DropdownButton<PomoSound>(
                    value: s.sound,
                    items: [for (final v in PomoSound.values) DropdownMenuItem(value: v, child: Text(pomoSoundLabel(t, v)))],
                    onChanged: (v) => set(s.copyWith(sound: v)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, s), child: Text(t.actionSave)),
          ],
        );
      },
    ),
  );
  if (saved == null) return;
  await saveFocusSettings(ref, saved);
  if (ref.read(focusProvider).phase == FocusPhase.idle) ref.read(focusProvider.notifier).setMode(ref.read(focusProvider).mode);
}

/// Focus module (`#focus`): Pomo / Cronômetro, the ring, the buttons of each state, the end
/// of the Pomo, the overview and "Foco em registro".
class FocusPage extends ConsumerWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;
    const main = _FocusMain();
    const side = _FocusSide();
    return ModuleScaffold(
      module: AppModule.focus,
      child: ColoredBox(
        color: tt.screen,
        child: narrow
            ? ListView(children: const [main, Divider(), side])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: SingleChildScrollView(child: main)),
                  Container(width: 1, color: tt.divider),
                  const SizedBox(width: 380, child: SingleChildScrollView(child: side)),
                ],
              ),
      ),
    );
  }
}

class _FocusMain extends ConsumerStatefulWidget {
  const _FocusMain();

  @override
  ConsumerState<_FocusMain> createState() => _FocusMainState();
}

class _FocusMainState extends ConsumerState<_FocusMain> {
  final _note = TextEditingController();

  /// The timer list (with saved timers) instead of the clock; opening the page mid-session shows the clock.
  late bool _list = ref.read(focusProvider).phase == FocusPhase.idle;

  /// "Foco" with, on the right, "+" (Adicionar temporizador.) and "…"; [back] returns to the timer list.
  Widget _header(AppLocalizations t, TtColors tt, {required bool back}) => Row(
    children: [
      const DrawerMenuButton(),
      if (back)
        IconButton(
          tooltip: t.focusTimers,
          icon: Icon(Icons.chevron_left, color: tt.textSecondary),
          onPressed: () => setState(() => _list = true),
        ),
      Text(
        t.focusTitle,
        style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
      ),
      const Spacer(),
      IconButton(
        tooltip: t.focusTimerAdd,
        icon: Icon(Icons.add, color: tt.textSecondary),
        onPressed: () => unawaited(editFocusTimer(context, ref)),
      ),
      PopupMenuButton<String>(
        tooltip: '',
        icon: Icon(Icons.more_horiz, color: tt.textSecondary),
        onSelected: (v) => switch (v) {
          'statistics' => context.go(Routes.statisticsOf('pomo')),
          'settings' => unawaited(showFocusSettings(context, ref)),
          _ => unawaited(showFocusRecordForm(context)),
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'statistics', height: 36, child: Text(t.statsTitle)),
          PopupMenuItem(value: 'settings', height: 36, child: Text(t.focusSettings)),
          PopupMenuItem(value: 'add', height: 36, child: Text(t.focusAddRecord)),
        ],
      ),
    ],
  );

  /// Mini player under the timer list: "Foco 25:00 ▶" when idle, "[timer] 24:51 ⏸" while focusing,
  /// "Pausado 24:43 ▶ ■" when paused. A click on it opens the clock.
  Widget _miniPlayer(
    AppLocalizations t,
    TtColors tt,
    FocusState focus,
    DateTime now,
    FocusSettings settings,
    List<FocusTimer> timers,
    String? linked,
  ) {
    final controller = ref.read(focusProvider.notifier);
    void open() => setState(() => _list = false);
    final idle = focus.phase == FocusPhase.idle;
    final timerName = timers.where((x) => x.id == focus.timerId).firstOrNull?.name;
    final label = switch (focus.phase) {
      FocusPhase.idle => t.navFocus,
      FocusPhase.focusing => timerName ?? linked ?? t.focusFocusing,
      FocusPhase.paused => t.focusPaused,
      FocusPhase.breaking => t.focusBreak,
      FocusPhase.pomoDone => t.focusDoneTitle,
    };
    final time = _clock(idle ? Duration(minutes: settings.pomoMinutes) : focus.shown(now));
    Widget button(IconData icon, String tooltip, VoidCallback onPressed) => IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      icon: Icon(icon, color: tt.primary),
      onPressed: onPressed,
    );
    return Material(
      color: tt.fieldFill,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 18, color: tt.primary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tt.text),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(color: tt.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(width: 4),
              if (idle)
                button(Icons.play_arrow, t.focusStart, () {
                  controller.start(mode: FocusMode.pomo);
                  open();
                })
              else if (focus.phase == FocusPhase.focusing)
                button(Icons.pause, t.focusPause, controller.pause)
              else if (focus.phase == FocusPhase.paused) ...[
                button(Icons.play_arrow, t.focusContinue, controller.resume),
                button(Icons.stop, t.focusEnd, () => unawaited(controller.finish())),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final focus = ref.watch(focusProvider);
    final controller = ref.read(focusProvider.notifier);
    if (focus.phase != FocusPhase.idle) ref.watch(focusClockProvider);
    final now = ref.read(clockProvider).now();
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final linked = focusLinkName(t, s, focus.taskId);
    final settings = ref.watch(preferencesProvider).value?.focus ?? const FocusSettings();
    final timers = ref.watch(preferencesProvider).value?.focusTimers ?? const <FocusTimer>[];
    final idle = focus.phase == FocusPhase.idle;
    // With a saved timer the screen is the list of timers and a mini player.
    if (timers.isNotEmpty && _list) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(t, tt, back: false),
            const SizedBox(height: 12),
            FocusTimerList(records: ref.watch(focusRecordsProvider).value ?? const [], onStart: () => setState(() => _list = false)),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: _miniPlayer(t, tt, focus, now, settings, timers, linked)),
          ],
        ),
      );
    }
    if (idle && _note.text.isNotEmpty) _note.clear();

    Widget button(String label, VoidCallback onPressed, {bool primary = true}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 150,
        height: 42,
        child: primary ? FilledButton(onPressed: onPressed, child: Text(label)) : OutlinedButton(onPressed: onPressed, child: Text(label)),
      ),
    );

    final buttons = switch (focus.phase) {
      FocusPhase.idle => [button(t.focusStart, controller.start)],
      FocusPhase.focusing => [button(t.focusPause, controller.pause, primary: false)],
      FocusPhase.paused => [button(t.focusContinue, controller.resume), button(t.focusEnd, () => unawaited(controller.finish()), primary: false)],
      // During the break, Terminar (ends it) · Sair.
      FocusPhase.breaking => [button(t.focusEndBreak, controller.skip), button(t.focusExit, controller.exit, primary: false)],
      FocusPhase.pomoDone => [
        button(t.focusRelax, controller.relax),
        button(t.focusSkip, controller.skip, primary: false),
        button(t.focusExit, controller.exit, primary: false),
      ],
    };

    final label = switch (focus.phase) {
      FocusPhase.paused => t.focusPaused,
      FocusPhase.breaking =>
        focus.breakLength.inMinutes >= settings.longBreakMinutes && settings.longBreakMinutes > settings.shortBreakMinutes
            ? t.focusLongBreak
            : t.focusBreak,
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          _header(t, tt, back: timers.isNotEmpty),
          const SizedBox(height: 8),
          SegmentedButton<FocusMode>(
            segments: [
              ButtonSegment(value: FocusMode.pomo, label: Text(t.focusTabPomo)),
              ButtonSegment(value: FocusMode.stopwatch, label: Text(t.focusTabStopwatch)),
            ],
            selected: {focus.mode},
            showSelectedIcon: false,
            onSelectionChanged: idle ? (v) => controller.setMode(v.first) : null,
          ),
          const SizedBox(height: 20),
          // "Foco": the linked task.
          TextButton.icon(
            // A task or a habit.
            onPressed: () async {
              final link = await pickFocusLink(context, ref, current: focus.taskId);
              if (link != null) controller.link(link.isEmpty ? null : link);
            },
            icon: Icon(Icons.adjust, size: 16, color: linked == null ? tt.textTertiary : tt.primary),
            label: Text(linked ?? t.focusLink, style: TextStyle(color: linked == null ? tt.textSecondary : tt.text)),
          ),
          const SizedBox(height: 12),
          if (focus.phase == FocusPhase.pomoDone) ...[
            const SizedBox(height: 30),
            const Text('🍅', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              t.focusDoneTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tt.text),
            ),
            const SizedBox(height: 6),
            Text(t.focusDoneBody(settings.shortBreakMinutes), style: TextStyle(color: tt.textSecondary)),
            // "Adicionar tempo extra" / "Editar duração do foco".
            if (focus.recordId != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    PopupMenuButton<int>(
                      tooltip: '',
                      onSelected: controller.extend,
                      itemBuilder: (_) => [
                        for (final m in const [5, 10, 15, 25]) PopupMenuItem(value: m, height: 36, child: Text(t.focusMinutesValue(m))),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(t.focusExtraTime, style: TextStyle(color: tt.primary)),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final minutes = await _askMinutes(context, t.focusEditDuration, focus.target.inMinutes);
                        if (minutes != null) await controller.editDuration(minutes);
                      },
                      child: Text(t.focusEditDuration),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
          ] else
            SizedBox(
              width: 280,
              height: 280,
              child: CustomPaint(
                painter: _RingPainter(
                  progress: focus.progress(now),
                  track: tt.divider,
                  color: focus.phase == FocusPhase.breaking ? tt.palette.green : tt.primary,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clock(idle && focus.mode == FocusMode.pomo ? Duration(minutes: settings.pomoMinutes) : focus.shown(now)),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w300,
                          color: tt.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (label != null) Text(label, style: TextStyle(color: tt.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
          // "+ / −" during a Pomo.
          if (focus.mode == FocusMode.pomo && (focus.phase == FocusPhase.focusing || focus.phase == FocusPhase.paused))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: t.focusLess5,
                  onPressed: () => controller.adjust(-5),
                  icon: Icon(Icons.remove_circle_outline, color: tt.textSecondary),
                ),
                const SizedBox(width: 24),
                IconButton(
                  tooltip: t.focusMore5,
                  onPressed: () => controller.adjust(5),
                  icon: Icon(Icons.add_circle_outline, color: tt.textSecondary),
                ),
              ],
            ),
          const SizedBox(height: 24),
          // Wraps on phones, where three buttons don't fit in a row.
          Wrap(alignment: WrapAlignment.center, runSpacing: 10, children: buttons),
          if (focus.phase == FocusPhase.focusing || focus.phase == FocusPhase.paused) ...[
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: TextField(
                controller: _note,
                minLines: 2,
                maxLines: 5,
                onChanged: controller.setNote,
                decoration: InputDecoration(
                  labelText: t.focusNotes,
                  hintText: t.focusNotesHint,
                  filled: true,
                  fillColor: tt.fieldFill,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.track, required this.color});

  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = track;
    canvas.drawCircle(center, radius, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color || old.track != track;
}

/// Right panel: "Visão geral" and "Foco em registro." grouped by day.
class _FocusSide extends ConsumerWidget {
  const _FocusSide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // During a session: the linked item and the day's timeline.
    if (ref.watch(focusProvider).phase != FocusPhase.idle) return const FocusSessionPanel();
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final records = ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[];
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final today = startOfDay(now);
    final todays = records.where((r) => daysBetween(today, r.startedAt.toLocal()) == 0).toList();
    int pomos(Iterable<FocusRecord> rs) => rs.where((r) => r.mode == FocusMode.pomo).length;
    Duration total(Iterable<FocusRecord> rs) => Duration(seconds: rs.fold(0, (sum, r) => sum + r.seconds));
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final dates = DateLabels(t);

    Widget card(String label, String value) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ],
        ),
      ),
    );

    final byDay = <DateTime, List<FocusRecord>>{};
    for (final r in records) {
      (byDay[startOfDay(r.startedAt.toLocal())] ??= []).add(r);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.focusOverview,
            style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
          ),
          const SizedBox(height: 8),
          Row(children: [card(t.focusTodayPomos, '${pomos(todays)}'), card(t.focusTodayDuration, _duration(t, total(todays)))]),
          Row(children: [card(t.focusTotalPomos, '${pomos(records)}'), card(t.focusTotalDuration, _duration(t, total(records)))]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.focusRecords,
                  style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: t.focusAddRecord,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => unawaited(showFocusRecordForm(context)),
              ),
              PopupMenuButton<String>(
                tooltip: '',
                icon: const Icon(Icons.more_horiz, size: 18),
                // "Gestão de Lotes · Exportar · Excluir tudo".
                onSelected: (v) async {
                  switch (v) {
                    case 'batch':
                      await showFocusBatch(context);
                    case 'export':
                      await exportFocusRecords(context, ref);
                    default:
                      if (await confirm(context, message: t.focusDeleteAll)) await ref.read(repositoryProvider).deleteAllFocusRecords();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'batch', height: 36, child: Text(t.focusBatch)),
                  PopupMenuItem(value: 'export', height: 36, child: Text(t.focusExport)),
                  PopupMenuItem(value: 'all', height: 36, child: Text(t.focusDeleteAll)),
                ],
              ),
            ],
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(t.focusRecordsEmpty, style: TextStyle(color: tt.textTertiary)),
              ),
            ),
          for (final day in byDay.keys) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                '${day.day} ${dates.monthShort(day)}',
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
            ),
            for (final r in byDay[day]!)
              InkWell(
                onTap: () => unawaited(showFocusRecordForm(context, editing: r)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r.mode == FocusMode.pomo ? Icons.timer_outlined : Icons.av_timer, size: 18, color: tt.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${DateLabels.time(r.startedAt.toLocal())} - ${DateLabels.time(r.endedAt.toLocal())}',
                              style: TextStyle(fontSize: TtText.body, color: tt.text),
                            ),
                            if (focusLinkName(t, s, r.taskId) case final name?)
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                              ),
                            if (r.note.isNotEmpty)
                              Text(
                                r.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _duration(t, Duration(seconds: r.seconds)),
                        style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// A number of minutes (1 to 600), or null when cancelled.
Future<int?> _askMinutes(BuildContext context, String title, int initial) async {
  final field = TextEditingController(text: '$initial');
  final t = AppLocalizations.of(context);
  int? parsed() {
    final v = int.tryParse(field.text.trim());
    return v != null && v > 0 && v <= 600 ? v : null;
  }

  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      content: TextField(
        controller: field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(suffixText: t.focusMinutesSuffix),
        onSubmitted: (_) => Navigator.pop(context, parsed()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, parsed()), child: Text(t.actionSave)),
      ],
    ),
  );
  field.dispose();
  return result;
}

/// "Foco em registro." popup: the linked task, the time, the note; also used to add a
/// record by hand.
/// A new record can start linked to [taskId] and belong to the saved timer [timerId] (the timer's
/// "Adicionar Registro").
Future<void> showFocusRecordForm(BuildContext context, {FocusRecord? editing, String? taskId, String? timerId}) => showDialog<void>(
  context: context,
  builder: (_) => _FocusRecordForm(editing: editing, taskId: taskId, timerId: timerId),
);

class _FocusRecordForm extends ConsumerStatefulWidget {
  const _FocusRecordForm({this.editing, this.taskId, this.timerId});

  final FocusRecord? editing;
  final String? taskId;
  final String? timerId;

  @override
  ConsumerState<_FocusRecordForm> createState() => _FocusRecordFormState();
}

class _FocusRecordFormState extends ConsumerState<_FocusRecordForm> {
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late String? _taskId = widget.editing?.taskId ?? widget.taskId;
  late DateTime _start = widget.editing?.startedAt.toLocal() ?? ref.read(clockProvider).now().subtract(const Duration(minutes: 25));
  late DateTime _end = widget.editing?.endedAt.toLocal() ?? ref.read(clockProvider).now();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimeDialog(context, initial: TimeOfDay.fromDateTime(current));
    if (picked == null) return;
    setState(() {
      final value = DateTime(current.year, current.month, current.day, picked.hour, picked.minute);
      start ? _start = value : _end = value;
    });
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    final editing = widget.editing;
    if (editing != null) {
      await repo.updateFocusRecord(editing.id, note: _note.text.trim(), taskId: Value(_taskId));
    } else if (_end.isAfter(_start)) {
      await repo.addFocusRecord(
        FocusRecordDraft(
          startedAt: _start,
          endedAt: _end,
          seconds: _end.difference(_start).inSeconds,
          mode: FocusMode.pomo,
          taskId: _taskId,
          note: _note.text.trim(),
          timerId: widget.timerId,
        ),
        timerId: widget.timerId,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final task = _taskId == null ? null : s.taskById[_taskId];
    final editing = widget.editing;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(t.focusRecords, style: const TextStyle(fontSize: 15))),
          if (editing != null)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: tt.textTertiary),
              onPressed: () async {
                await ref.read(repositoryProvider).deleteFocusRecord(editing.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              onPressed: () async {
                final picked = await pickTaskToLink(context);
                if (picked != null) setState(() => _taskId = picked.id);
              },
              icon: const Icon(Icons.adjust, size: 16),
              label: Text(task == null ? t.focusNoTask : task.title),
            ),
            if (editing == null)
              Row(
                children: [
                  TextButton(onPressed: () => unawaited(_pickTime(start: true)), child: Text('${t.focusRecordStart} ${DateLabels.time(_start)}')),
                  TextButton(onPressed: () => unawaited(_pickTime(start: false)), child: Text('${t.focusRecordEnd} ${DateLabels.time(_end)}')),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${DateLabels(t).detailDate(_start, isAllDay: true, today: startOfDay(ref.read(clockProvider).now()))}, ${DateLabels.time(_start)} - ${DateLabels.time(_end)} · ${_duration(t, Duration(seconds: editing.seconds))}',
                  style: TextStyle(color: tt.textSecondary),
                ),
              ),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(hintText: t.focusNotesHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => unawaited(_save()), child: Text(t.actionSave)),
      ],
    );
  }
}

/// Opens the focus module after starting a session for [task] (task menu › "Começar o foco").
void startFocusFor(BuildContext context, WidgetRef ref, Task task, FocusMode mode) {
  ref.read(focusProvider.notifier).start(mode: mode, taskId: task.id);
  context.go(Routes.focus);
}
