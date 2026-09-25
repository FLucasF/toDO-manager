import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/focus.dart';
import 'focus_controller.dart';
import 'providers.dart';
import 'reminders.dart' show reminderTexts;

/// "Tempo de execução nas guias do navegador" as the window title: "24:51 · Tarefas"
/// while a session runs, "Pausado 24:43 · Tarefas" paused; just the app name otherwise or when the
/// option is off.
final windowTitleProvider = Provider<String>((ref) {
  final t = reminderTexts;
  final focus = ref.watch(focusProvider);
  final enabled = ref.watch(preferencesProvider).value?.focus.timeInTitle ?? false;
  final active = focus.phase == FocusPhase.focusing || focus.phase == FocusPhase.paused || focus.phase == FocusPhase.breaking;
  if (!enabled || !active) return t.appTitle;
  ref.watch(focusClockProvider);
  final shown = focus.shown(ref.read(clockProvider).now());
  final m = shown.inMinutes, sec = shown.inSeconds % 60;
  final time = '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  final label = switch (focus.phase) {
    FocusPhase.paused => '${t.focusPaused} $time',
    FocusPhase.breaking => '${t.focusBreak} $time',
    _ => time,
  };
  return '$label · ${t.appTitle}';
});
