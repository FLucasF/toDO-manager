import 'enums.dart';

/// "Som do Pomo": the sound of the end-of-Pomo notification. [alarm] is the
/// "Despertador" (assets/sounds/despertador.wav), ringing until stopped; it is the default.
enum PomoSound { standard, alarm, reminder, message, silent }

/// "Configurações de foco".
class FocusSettings {
  const FocusSettings({
    this.pomoMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.pomosBeforeLongBreak = 4,
    this.autoStartPomo = false,
    this.autoStartBreak = false,
    this.sound = PomoSound.alarm,
    this.timeInTitle = false,
  });

  final int pomoMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int pomosBeforeLongBreak;
  final bool autoStartPomo;
  final bool autoStartBreak;
  final PomoSound sound;

  /// "Tempo de execução nas guias do navegador": the running timer in the window title.
  final bool timeInTitle;

  FocusSettings copyWith({
    int? pomoMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? pomosBeforeLongBreak,
    bool? autoStartPomo,
    bool? autoStartBreak,
    PomoSound? sound,
    bool? timeInTitle,
  }) => FocusSettings(
    pomoMinutes: pomoMinutes == null ? this.pomoMinutes : clampPomo(pomoMinutes),
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    pomosBeforeLongBreak: pomosBeforeLongBreak ?? this.pomosBeforeLongBreak,
    autoStartPomo: autoStartPomo ?? this.autoStartPomo,
    autoStartBreak: autoStartBreak ?? this.autoStartBreak,
    sound: sound ?? this.sound,
    timeInTitle: timeInTitle ?? this.timeInTitle,
  );

  /// These settings with another Pomo length (a saved timer's).
  FocusSettings withPomo(int minutes) => copyWith(pomoMinutes: minutes);

  /// The Pomo is at least 5 minutes (typing 1 becomes 5).
  static int clampPomo(int minutes) => minutes < 5 ? 5 : (minutes > 180 ? 180 : minutes);

  Map<String, Object> toJson() => {
    'pomo': pomoMinutes,
    'short': shortBreakMinutes,
    'long': longBreakMinutes,
    'every': pomosBeforeLongBreak,
    'autoPomo': autoStartPomo,
    'autoBreak': autoStartBreak,
    'sound': sound.name,
    'title': timeInTitle,
  };

  static FocusSettings fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const FocusSettings();
    int number(String key, int fallback) => switch (json[key]) {
      final int v when v > 0 => v,
      _ => fallback,
    };
    return FocusSettings(
      pomoMinutes: clampPomo(number('pomo', 25)),
      shortBreakMinutes: number('short', 5),
      longBreakMinutes: number('long', 15),
      pomosBeforeLongBreak: number('every', 4),
      autoStartPomo: json['autoPomo'] == true,
      autoStartBreak: json['autoBreak'] == true,
      sound: PomoSound.values.where((v) => v.name == json['sound']).firstOrNull ?? PomoSound.alarm,
      timeInTitle: json['title'] == true,
    );
  }
}

enum FocusPhase { idle, focusing, paused, pomoDone, breaking }

/// A focus session linked to a habit keeps `habit:<id>` where the task id goes.
const habitFocusPrefix = 'habit:';

/// The habit of a focus link, or null when it is a task (or nothing).
String? focusHabitId(String? link) => link != null && link.startsWith(habitFocusPrefix) ? link.substring(habitFocusPrefix.length) : null;

/// "Timers salvos": a named focus shortcut with its mode, length and link.
class FocusTimer {
  const FocusTimer({required this.id, required this.name, this.mode = FocusMode.pomo, this.minutes = 25, this.link, this.archived = false});

  final String id;
  final String name;
  final FocusMode mode;

  /// Pomo length (the stopwatch counts up and ignores it).
  final int minutes;

  /// A task id or `habit:<id>`.
  final String? link;

  /// In the "Arquivado" tab of the timer list.
  final bool archived;

  FocusTimer withArchived(bool value) => FocusTimer(id: id, name: name, mode: mode, minutes: minutes, link: link, archived: value);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'mode': mode.code, 'minutes': minutes, 'link': link, 'archived': archived};

  static FocusTimer? fromJson(Object? json) {
    if (json is! Map<String, Object?> || json['id'] is! String || json['name'] is! String) return null;
    return FocusTimer(
      id: json['id']! as String,
      name: json['name']! as String,
      mode: FocusMode.values.where((m) => m.code == json['mode']).firstOrNull ?? FocusMode.pomo,
      minutes: json['minutes'] is int ? FocusSettings.clampPomo(json['minutes']! as int) : 25,
      link: json['link'] is String ? json['link']! as String : null,
      archived: json['archived'] == true,
    );
  }
}

/// A focus session to save as a record.
class FocusRecordDraft {
  const FocusRecordDraft({
    required this.startedAt,
    required this.endedAt,
    required this.seconds,
    required this.mode,
    this.taskId,
    this.note = '',
    this.timerId,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int seconds;
  final FocusMode mode;
  final String? taskId;
  final String note;

  /// The saved timer that ran it.
  final String? timerId;
}

/// State of the focus timer. Time is derived from timestamps, so it stays right when the app sleeps.
class FocusState {
  const FocusState({
    this.phase = FocusPhase.idle,
    this.mode = FocusMode.pomo,
    this.target = const Duration(minutes: 25),
    this.startedAt,
    this.runningSince,
    this.accumulated = Duration.zero,
    this.taskId,
    this.note = '',
    this.pomosInCycle = 0,
    this.breakEndsAt,
    this.breakLength = Duration.zero,
    this.timerId,
    this.recordId,
  });

  /// The saved timer that started the session, if any.
  final String? timerId;

  /// The record saved when this Pomo ended: "Adicionar tempo extra" grows it and "Editar duração do
  /// foco" changes it.
  final String? recordId;

  final FocusPhase phase;
  final FocusMode mode;

  /// Pomo length.
  final Duration target;
  final DateTime? startedAt;

  /// Since when it is running (null while paused or idle).
  final DateTime? runningSince;

  /// Focused time before [runningSince].
  final Duration accumulated;
  final String? taskId;
  final String note;

  /// Pomos finished since the last long break.
  final int pomosInCycle;
  final DateTime? breakEndsAt;
  final Duration breakLength;

  Duration elapsed(DateTime now) => accumulated + (runningSince == null ? Duration.zero : now.difference(runningSince!));

  /// Pomo: time left; Cronômetro: time so far; break: time left of the break.
  Duration shown(DateTime now) => switch (phase) {
    FocusPhase.breaking => _nonNegative(breakEndsAt!.difference(now)),
    FocusPhase.pomoDone => Duration.zero,
    _ => mode == FocusMode.pomo ? _nonNegative(target - elapsed(now)) : elapsed(now),
  };

  /// 0..1 for the ring (the Cronômetro fills once an hour).
  double progress(DateTime now) => switch (phase) {
    FocusPhase.idle => 0,
    FocusPhase.pomoDone => 1,
    FocusPhase.breaking => breakLength.inSeconds == 0 ? 1 : 1 - shown(now).inSeconds / breakLength.inSeconds,
    _ => mode == FocusMode.pomo ? (elapsed(now).inSeconds / target.inSeconds).clamp(0, 1).toDouble() : (elapsed(now).inSeconds % 3600) / 3600,
  };

  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

  /// Saved while a session runs, so it goes on after the app is closed and opened again.
  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'mode': mode.code,
    'target': target.inSeconds,
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'runningSince': runningSince?.toUtc().toIso8601String(),
    'accumulated': accumulated.inSeconds,
    'taskId': taskId,
    'note': note,
    'pomos': pomosInCycle,
    'breakEndsAt': breakEndsAt?.toUtc().toIso8601String(),
    'breakLength': breakLength.inSeconds,
    'timerId': timerId,
    'recordId': recordId,
  };

  static FocusState? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    DateTime? time(String key) => json[key] is String ? DateTime.tryParse(json[key]! as String)?.toLocal() : null;
    Duration seconds(String key) => Duration(seconds: json[key] is int ? json[key]! as int : 0);
    final phase = FocusPhase.values.where((p) => p.name == json['phase']).firstOrNull;
    final mode = FocusMode.values.where((m) => m.code == json['mode']).firstOrNull;
    if (phase == null || mode == null) return null;
    return FocusState(
      phase: phase,
      mode: mode,
      target: seconds('target'),
      startedAt: time('startedAt'),
      runningSince: time('runningSince'),
      accumulated: seconds('accumulated'),
      taskId: json['taskId'] as String?,
      note: json['note'] as String? ?? '',
      pomosInCycle: json['pomos'] is int ? json['pomos']! as int : 0,
      breakEndsAt: time('breakEndsAt'),
      breakLength: seconds('breakLength'),
      timerId: json['timerId'] as String?,
      recordId: json['recordId'] as String?,
    );
  }

  FocusState copyWith({
    FocusPhase? phase,
    FocusMode? mode,
    Duration? target,
    DateTime? startedAt,
    DateTime? Function()? runningSince,
    Duration? accumulated,
    String? Function()? taskId,
    String? Function()? timerId,
    String? note,
    int? pomosInCycle,
    DateTime? Function()? breakEndsAt,
    Duration? breakLength,
    String? Function()? recordId,
  }) => FocusState(
    phase: phase ?? this.phase,
    mode: mode ?? this.mode,
    target: target ?? this.target,
    startedAt: startedAt ?? this.startedAt,
    runningSince: runningSince == null ? this.runningSince : runningSince(),
    accumulated: accumulated ?? this.accumulated,
    taskId: taskId == null ? this.taskId : taskId(),
    timerId: timerId == null ? this.timerId : timerId(),
    note: note ?? this.note,
    pomosInCycle: pomosInCycle ?? this.pomosInCycle,
    breakEndsAt: breakEndsAt == null ? this.breakEndsAt : breakEndsAt(),
    breakLength: breakLength ?? this.breakLength,
    recordId: recordId == null ? this.recordId : recordId(),
  );
}

/// Transitions of the focus timer. Pure: the caller keeps the state, saves the
/// returned records and schedules the end-of-Pomo notification.
abstract final class FocusEngine {
  /// Sessions shorter than this leave no record ("Fim" right after "Começar", §13.1).
  static const minimumRecord = Duration(minutes: 1);

  static FocusState start(FocusState s, DateTime now, {required FocusMode mode, required FocusSettings settings}) => FocusState(
    phase: FocusPhase.focusing,
    mode: mode,
    target: Duration(minutes: settings.pomoMinutes),
    startedAt: now,
    runningSince: now,
    taskId: s.taskId,
    timerId: s.timerId,
    pomosInCycle: s.pomosInCycle,
  );

  /// "+ / −" during a Pomo: [minutes] more or less, never under a minute left.
  static FocusState adjust(FocusState s, DateTime now, int minutes) {
    if (s.mode != FocusMode.pomo || (s.phase != FocusPhase.focusing && s.phase != FocusPhase.paused)) return s;
    final floor = s.elapsed(now) + const Duration(minutes: 1);
    final target = s.target + Duration(minutes: minutes);
    return s.copyWith(target: target < floor ? floor : target);
  }

  /// "Adicionar tempo extra" at the end of a Pomo: it runs [minutes] more and its record grows.
  static FocusState extend(FocusState s, DateTime now, int minutes) {
    if (s.phase != FocusPhase.pomoDone || s.recordId == null) return s;
    return s.copyWith(
      phase: FocusPhase.focusing,
      target: s.target + Duration(minutes: minutes),
      runningSince: () => now,
    );
  }

  static FocusState pause(FocusState s, DateTime now) =>
      s.phase != FocusPhase.focusing ? s : s.copyWith(phase: FocusPhase.paused, accumulated: s.elapsed(now), runningSince: () => null);

  static FocusState resume(FocusState s, DateTime now) =>
      s.phase != FocusPhase.paused ? s : s.copyWith(phase: FocusPhase.focusing, runningSince: () => now);

  static FocusRecordDraft? _record(FocusState s, DateTime now) {
    final elapsed = s.mode == FocusMode.pomo && s.elapsed(now) > s.target ? s.target : s.elapsed(now);
    if (s.startedAt == null || elapsed < minimumRecord) return null;
    return FocusRecordDraft(
      startedAt: s.startedAt!,
      endedAt: now,
      seconds: elapsed.inSeconds,
      mode: s.mode,
      taskId: s.taskId,
      timerId: s.timerId,
      note: s.note.trim(),
    );
  }

  /// "Fim": ends the session (a record when it lasted a minute or more) and goes back to idle.
  static (FocusState, FocusRecordDraft?) finish(FocusState s, DateTime now) {
    if (s.phase != FocusPhase.focusing && s.phase != FocusPhase.paused) return (s, null);
    return (FocusState(mode: s.mode, target: s.target, taskId: s.taskId, timerId: s.timerId, pomosInCycle: s.pomosInCycle), _record(s, now));
  }

  /// Called every second: a Pomo that reached its length ends ("Você tem um Pomo."), a break that
  /// ended goes back to idle or, with "Início automático", starts the next Pomo.
  static (FocusState, FocusRecordDraft?) tick(FocusState s, DateTime now, FocusSettings settings) {
    if (s.phase == FocusPhase.focusing && s.mode == FocusMode.pomo && s.elapsed(now) >= s.target) {
      final endedAt = s.runningSince!.add(s.target - s.accumulated);
      // Extra time ends the same Pomo again: it is not counted twice.
      final pomos = s.recordId == null ? s.pomosInCycle + 1 : s.pomosInCycle;
      final done = s.copyWith(phase: FocusPhase.pomoDone, accumulated: s.target, runningSince: () => null, pomosInCycle: pomos);
      final record = _record(s, endedAt);
      return (settings.autoStartBreak ? relax(done, now, settings) : done, record);
    }
    if (s.phase == FocusPhase.breaking && !now.isBefore(s.breakEndsAt!)) {
      final idle = FocusState(mode: FocusMode.pomo, target: s.target, taskId: s.taskId, timerId: s.timerId, pomosInCycle: s.pomosInCycle);
      return (settings.autoStartPomo ? start(idle, now, mode: FocusMode.pomo, settings: settings) : idle, null);
    }
    return (s, null);
  }

  /// "Relaxar": the short break, or the long one after [FocusSettings.pomosBeforeLongBreak] Pomos.
  static FocusState relax(FocusState s, DateTime now, FocusSettings settings) {
    final long = s.pomosInCycle >= settings.pomosBeforeLongBreak;
    final length = Duration(minutes: long ? settings.longBreakMinutes : settings.shortBreakMinutes);
    return s.copyWith(phase: FocusPhase.breaking, breakEndsAt: () => now.add(length), breakLength: length, pomosInCycle: long ? 0 : s.pomosInCycle);
  }

  /// "Pular" (skip the break) and "Sair": back to idle, keeping the link.
  static FocusState skip(FocusState s, DateTime now, FocusSettings settings) {
    final idle = FocusState(mode: FocusMode.pomo, target: s.target, taskId: s.taskId, timerId: s.timerId, pomosInCycle: s.pomosInCycle);
    return settings.autoStartPomo && s.phase == FocusPhase.pomoDone ? start(idle, now, mode: FocusMode.pomo, settings: settings) : idle;
  }

  static FocusState exit(FocusState s) =>
      FocusState(mode: s.mode, target: s.target, taskId: s.taskId, timerId: s.timerId, pomosInCycle: s.pomosInCycle);
}
