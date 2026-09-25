import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';

void main() {
  final t0 = DateTime(2026, 9, 25, 18, 24);
  const settings = FocusSettings(pomoMinutes: 25);
  DateTime at(int minutes, [int seconds = 0]) => t0.add(Duration(minutes: minutes, seconds: seconds));

  test('"+ / −" changes a running Pomo, never below a minute left, and nothing else', () {
    var s = FocusEngine.start(const FocusState(), t0, mode: FocusMode.pomo, settings: settings);
    s = FocusEngine.adjust(s, at(10), 5);
    expect(s.shown(at(10)), const Duration(minutes: 20));
    s = FocusEngine.adjust(s, at(10), -5);
    s = FocusEngine.adjust(s, at(10), -5);
    expect(s.shown(at(10)), const Duration(minutes: 10));
    s = FocusEngine.adjust(s, at(10), -30);
    expect(s.shown(at(10)), const Duration(minutes: 1), reason: 'at least a minute is left');
    s = FocusEngine.pause(s, at(10, 30));
    expect(FocusEngine.adjust(s, at(20), 5).shown(at(20)), const Duration(minutes: 5, seconds: 30), reason: 'works while paused');
    final watch = FocusEngine.start(const FocusState(), t0, mode: FocusMode.stopwatch, settings: settings);
    expect(FocusEngine.adjust(watch, at(1), 5).target, watch.target, reason: 'a stopwatch has no length');
  });

  test('"Adicionar tempo extra" runs the ended Pomo again and its record grows; it is not counted twice', () {
    final s = FocusEngine.start(const FocusState(), t0, mode: FocusMode.pomo, settings: settings);
    var (done, record) = FocusEngine.tick(s, at(26), settings);
    expect(FocusEngine.extend(done, at(26), 5).phase, FocusPhase.pomoDone, reason: 'only once its record is saved');
    done = done.copyWith(recordId: () => 'r1');
    final extra = FocusEngine.extend(done, at(27), 5);
    expect((extra.phase, extra.shown(at(27)), extra.recordId), (FocusPhase.focusing, const Duration(minutes: 5), 'r1'));
    (done, record) = FocusEngine.tick(extra, at(33), settings);
    expect(done.phase, FocusPhase.pomoDone);
    expect(done.pomosInCycle, 1);
    expect((record!.startedAt, record.endedAt, record.seconds), (t0, at(32), 30 * 60));
  });

  test('a Pomo counts down, pauses without counting and ends with a record', () {
    var s = FocusEngine.start(
      const FocusState(taskId: 'task-1'),
      t0,
      mode: FocusMode.pomo,
      settings: settings,
    );
    expect(s.shown(at(10)), const Duration(minutes: 15));
    s = FocusEngine.pause(s, at(10));
    expect(s.shown(at(40)), const Duration(minutes: 15), reason: 'paused time does not count');
    s = FocusEngine.resume(s, at(40));
    var (next, record) = FocusEngine.tick(s, at(54), settings);
    expect((next.phase, record), (FocusPhase.focusing, null));
    (next, record) = FocusEngine.tick(s, at(56), settings);
    expect(next.phase, FocusPhase.pomoDone);
    expect(next.pomosInCycle, 1);
    expect(record!.seconds, 25 * 60);
    expect(record.endedAt, at(55), reason: 'the Pomo ended when its 25 minutes were done');
    expect(record.taskId, 'task-1');
  });

  test('"Fim" right after "Começar" leaves no record; a stopwatch records what it counted', () {
    final s = FocusEngine.start(const FocusState(), t0, mode: FocusMode.pomo, settings: settings);
    expect(FocusEngine.finish(s, at(0, 20)).$2, isNull);

    final w = FocusEngine.start(const FocusState(), t0, mode: FocusMode.stopwatch, settings: settings);
    expect(w.shown(at(7)), const Duration(minutes: 7));
    final (idle, record) = FocusEngine.finish(w, at(7));
    expect((idle.phase, record!.seconds, record.mode), (FocusPhase.idle, 420, FocusMode.stopwatch));
  });

  test('breaks: short, then long after 4 Pomos; the end of the break goes back to idle', () {
    var s = const FocusState(phase: FocusPhase.pomoDone, pomosInCycle: 1);
    s = FocusEngine.relax(s, t0, settings);
    expect((s.phase, s.breakLength), (FocusPhase.breaking, const Duration(minutes: 5)));
    expect(FocusEngine.tick(s, at(5), settings).$1.phase, FocusPhase.idle);

    final long = FocusEngine.relax(const FocusState(phase: FocusPhase.pomoDone, pomosInCycle: 4), t0, settings);
    expect((long.breakLength, long.pomosInCycle), (const Duration(minutes: 15), 0));

    const auto = FocusSettings(autoStartPomo: true);
    expect(FocusEngine.tick(s, at(5), auto).$1.phase, FocusPhase.focusing);
  });

  test('settings round-trip and the 5-minute minimum', () {
    const custom = FocusSettings(pomoMinutes: 50, shortBreakMinutes: 10, autoStartBreak: true, sound: PomoSound.silent);
    final back = FocusSettings.fromJson(custom.toJson());
    expect((back.pomoMinutes, back.shortBreakMinutes, back.autoStartBreak, back.sound), (50, 10, true, PomoSound.silent));
    expect(back.copyWith(pomoMinutes: 2).pomoMinutes, 5, reason: 'copyWith keeps the minimum');
    expect(FocusSettings.fromJson(const {'sound': 'x'}).sound, PomoSound.alarm, reason: 'the Despertador is the default');
    expect(FocusSettings.clampPomo(1), 5);
    expect(FocusSettings.fromJson('garbage').pomoMinutes, 25);
  });

  test('a saved timer runs with its length and link, and its records carry it', () {
    const timer = FocusTimer(id: 'tm', name: 'Leitura', minutes: 10, link: '${habitFocusPrefix}h1');
    final back = FocusTimer.fromJson(timer.toJson())!;
    expect((back.name, back.minutes, back.link, back.mode), ('Leitura', 10, 'habit:h1', FocusMode.pomo));
    expect(focusHabitId(back.link), 'h1');
    expect(focusHabitId('task-id'), isNull);

    final s = FocusEngine.start(
      const FocusState(taskId: 'habit:h1', timerId: 'tm'),
      t0,
      mode: FocusMode.pomo,
      settings: settings.withPomo(10),
    );
    expect(s.target, const Duration(minutes: 10));
    final (_, record) = FocusEngine.finish(s, at(6));
    expect((record!.timerId, record.taskId), ('tm', 'habit:h1'));
  });
}
