import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../domain/focus.dart';
import 'providers.dart';
import '../platform/desktop_shell.dart';
import '../platform/notifications.dart';
import 'reminders.dart';

/// Notification id of the end of the running Pomo or break (one at a time).
const _pomoEndNotificationId = 900001;

/// Android: the running timer in the notification shade.
const _runningNotificationId = 900002;

/// The focus timer of the whole app: it keeps running while the user moves between
/// modules, saves the records and schedules the end-of-Pomo notification, so it arrives even with the
/// app closed.
class FocusController extends Notifier<FocusState> {
  Timer? _ticker;

  /// Windows: just before the end, the system's notification is swapped for a silent one, so the
  /// despertador the app plays doesn't sound over it.
  Timer? _mute;

  FocusSettings get _settings => ref.read(preferencesProvider).value?.focus ?? const FocusSettings();

  DateTime get _now => ref.read(clockProvider).now();

  @override
  FocusState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _mute?.cancel();
    });
    unawaited(Future.microtask(_restore));
    return FocusState(target: Duration(minutes: _settings.pomoMinutes));
  }

  /// A session that was running when the app closed goes on (time comes from timestamps); a Pomo that
  /// ended meanwhile is recorded as ended at its time.
  Future<void> _restore() async {
    try {
      final saved = FocusState.fromJson((await ref.read(preferencesRepositoryProvider).watch().first).focusRun);
      if (saved == null || state.phase != FocusPhase.idle || !ref.mounted) return;
      _set(saved);
      tick(restoring: true);
    } on Object catch (e) {
      debugPrint('Focus session not restored: $e');
    }
  }

  /// [timeUp]: the Pomo or the break ran out (not a button): the despertador rings on Windows.
  void _set(FocusState next, {bool timeUp = false}) {
    if (timeUp && DesktopShell.available && _settings.sound == PomoSound.alarm) {
      unawaited(DesktopShell.playAlarm(loop: true));
    } else if (!timeUp) {
      unawaited(DesktopShell.stopAlarm());
    }
    state = next;
    final active = next.phase == FocusPhase.focusing || next.phase == FocusPhase.breaking;
    if (active && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    } else if (!active) {
      _ticker?.cancel();
      _ticker = null;
    }
    unawaited(_scheduleEndNotification());
    unawaited(_persist(next));
  }

  Future<void> _persist(FocusState s) async {
    try {
      await ref.read(preferencesRepositoryProvider).setFocusRun(s.phase == FocusPhase.idle ? null : s.toJson());
    } on Object catch (e) {
      debugPrint('Focus session not saved: $e');
    }
  }

  /// Saves a record, or rewrites [replacing] when the session was extra time on it.
  Future<void> _save(FocusRecordDraft? record, {String? replacing}) async {
    if (record == null) return;
    final repo = ref.read(repositoryProvider);
    if (replacing != null) {
      await repo.updateFocusRecord(replacing, note: record.note, startedAt: record.startedAt, endedAt: record.endedAt, seconds: record.seconds);
      return;
    }
    final id = await repo.addFocusRecord(record, timerId: record.timerId);
    // The Pomo that just ended can still get extra time or a new duration.
    final s = state;
    if (s.recordId == null && (s.phase == FocusPhase.pomoDone || s.phase == FocusPhase.breaking)) state = s.copyWith(recordId: () => id);
  }

  /// Keeps one OS notification at the end of the running Pomo or break (scheduled with the system, so
  /// it arrives with the app closed) and, on Android, the running timer in the notification shade.
  Future<void> _scheduleEndNotification() async {
    final service = ref.read(reminderSetupProvider)?.service;
    if (service == null) return;
    try {
      await service.cancel(_pomoEndNotificationId);
      _mute?.cancel();
      final s = state;
      final t = reminderTexts;
      if (s.phase == FocusPhase.focusing && s.mode == FocusMode.pomo && s.runningSince != null) {
        _muteBefore(service, s.runningSince!.add(s.target - s.accumulated), t.focusDoneTitle, t.focusDoneBody(_settings.shortBreakMinutes));
        await service.schedule(
          id: _pomoEndNotificationId,
          taskId: focusNotificationTask,
          title: t.focusDoneTitle,
          body: t.focusDoneBody(_settings.shortBreakMinutes),
          at: s.runningSince!.add(s.target - s.accumulated),
          withActions: false,
          sound: _settings.sound,
        );
      } else if (s.phase == FocusPhase.breaking && s.breakEndsAt != null) {
        _muteBefore(service, s.breakEndsAt!, t.focusBreakDoneTitle, t.focusBreakDoneBody);
        await service.schedule(
          id: _pomoEndNotificationId,
          taskId: focusNotificationTask,
          title: t.focusBreakDoneTitle,
          body: t.focusBreakDoneBody,
          at: s.breakEndsAt!,
          withActions: false,
          sound: _settings.sound,
        );
      }
      await _showRunning(service, s);
    } on Object catch (e) {
      debugPrint('Focus notification not scheduled: $e');
    }
  }

  /// Windows with the despertador: two seconds before [at], the end notification is scheduled again
  /// without sound; the app rings when the time is up (a closed app leaves Windows' alarm sound).
  void _muteBefore(NotificationService service, DateTime at, String title, String body) {
    if (!DesktopShell.available || _settings.sound != PomoSound.alarm) return;
    final wait = at.subtract(const Duration(seconds: 2)).difference(_now);
    if (wait.isNegative) return;
    _mute = Timer(wait, () async {
      await service.cancel(_pomoEndNotificationId);
      await service.schedule(
        id: _pomoEndNotificationId,
        taskId: focusNotificationTask,
        title: title,
        body: body,
        at: at,
        withActions: false,
        sound: _settings.sound,
        muted: true,
      );
    });
  }

  Future<void> _showRunning(NotificationService service, FocusState s) async {
    final t = reminderTexts;
    final task = s.taskId == null ? null : ref.read(snapshotProvider).value?.taskById[s.taskId];
    final body = task?.title;
    switch (s.phase) {
      case FocusPhase.focusing when s.runningSince != null:
        await service.showFocusRunning(
          id: _runningNotificationId,
          title: t.focusRunningTitle,
          body: body,
          countdownTo: s.mode == FocusMode.pomo ? s.runningSince!.add(s.target - s.accumulated) : null,
          countUpFrom: s.mode == FocusMode.stopwatch ? s.runningSince!.subtract(s.accumulated) : null,
        );
      case FocusPhase.paused:
        await service.showFocusRunning(id: _runningNotificationId, title: t.focusPausedTitle, body: body);
      case FocusPhase.breaking when s.breakEndsAt != null:
        await service.showFocusRunning(id: _runningNotificationId, title: t.focusBreakTitle, countdownTo: s.breakEndsAt);
      case _:
        await service.cancel(_runningNotificationId);
    }
  }

  /// Links the next session to a task (or clears it).
  void link(String? taskId) => _set(state.copyWith(taskId: () => taskId));

  void setNote(String note) => state = state.copyWith(note: note);

  /// Switches Pomo / Cronômetro while idle.
  void setMode(FocusMode mode) {
    if (state.phase != FocusPhase.idle) return;
    _set(
      state.copyWith(
        mode: mode,
        target: Duration(minutes: _settings.pomoMinutes),
      ),
    );
  }

  void start({FocusMode? mode, String? taskId}) {
    final base = (taskId == null ? state : state.copyWith(taskId: () => taskId)).copyWith(timerId: () => null);
    _set(FocusEngine.start(base, _now, mode: mode ?? state.mode, settings: _settings));
  }

  /// Starts a saved timer: its mode, length and link.
  void startTimer(FocusTimer timer) {
    if (state.phase != FocusPhase.idle) return;
    final base = state.copyWith(taskId: () => timer.link, timerId: () => timer.id);
    _set(FocusEngine.start(base, _now, mode: timer.mode, settings: _settings.withPomo(timer.minutes)));
  }

  void pause() => _set(FocusEngine.pause(state, _now));

  /// "+5" / "−5" while a Pomo runs.
  void adjust(int minutes) => _set(FocusEngine.adjust(state, _now, minutes));

  void resume() => _set(FocusEngine.resume(state, _now));

  /// Ctrl+Shift+P: start, pause or continue.
  void toggle() => switch (state.phase) {
    FocusPhase.idle => start(),
    FocusPhase.focusing => pause(),
    FocusPhase.paused => resume(),
    FocusPhase.pomoDone || FocusPhase.breaking => null,
  };

  Future<void> finish() async {
    final replacing = state.recordId;
    final (next, record) = FocusEngine.finish(state, _now);
    _set(next);
    await _save(record, replacing: replacing);
  }

  /// [restoring]: the first tick after the app opened; a session that ended long before doesn't ring.
  void tick({bool restoring = false}) {
    final replacing = state.recordId;
    final before = state;
    final (next, record) = FocusEngine.tick(state, _now, _settings);
    if (!identical(next, state)) {
      final end = switch (before.phase) {
        FocusPhase.breaking => before.breakEndsAt,
        _ => before.runningSince?.add(before.target - before.accumulated),
      };
      final recent = end != null && _now.difference(end) < const Duration(minutes: 1);
      _set(next, timeUp: !restoring || recent);
    }
    unawaited(_save(record, replacing: replacing));
  }

  /// "Adicionar tempo extra".
  void extend(int minutes) => _set(FocusEngine.extend(state, _now, minutes));

  /// "Editar duração do foco": the Pomo that just ended counts [minutes].
  Future<void> editDuration(int minutes) async {
    final id = state.recordId;
    if (id == null || minutes <= 0) return;
    await ref.read(repositoryProvider).setFocusRecordLength(id, minutes * 60);
  }

  void relax() => _set(FocusEngine.relax(state, _now, _settings));

  void skip() => _set(FocusEngine.skip(state, _now, _settings));

  void exit() => _set(FocusEngine.exit(state));
}

final focusProvider = NotifierProvider<FocusController, FocusState>(FocusController.new);

/// Rebuilds the focus clock every second while something runs.
final focusClockProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
});

Future<void> saveFocusSettings(WidgetRef ref, FocusSettings settings) => ref.read(preferencesRepositoryProvider).setFocusSettings(settings);

/// Formats focused time as TickTick does: "5m", "1h 20m".
String focusDuration(Duration d, {required String Function(int) hours, required String Function(int) minutes}) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h == 0) return minutes(m);
  return m == 0 ? hours(h) : '${hours(h)} ${minutes(m)}';
}
