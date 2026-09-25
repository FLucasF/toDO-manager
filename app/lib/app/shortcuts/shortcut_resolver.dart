import 'package:flutter/services.dart';

import 'shortcut_bindings.dart';
import 'shortcut_detector.dart';

/// Everything the keyboard can do outside text fields.
enum ShortcutAction {
  addTask,
  addTaskBelow,
  addSubtask,
  toggleSubtasks,
  search,
  palette,
  help,
  escape,
  complete,
  pin,
  delete,
  setDate,
  noDate,
  today,
  tomorrow,
  nextWeek,
  priorityNone,
  priorityLow,
  priorityMedium,
  priorityHigh,
  goAll,
  goToday,
  goTomorrow,
  goNext7Days,
  goInbox,
  goCompleted,
  goWontDo,
  goSummary,
  goTrash,
  goSettings,
  viewList,
  viewKanban,
  viewTimeline,
  print,
  focusToggle,
  undo,
  redo,
}

/// Turns key events into [ShortcutAction]s: modifier combos (Ctrl+K, Ctrl+Delete, Alt+digit), single keys
/// (`/`, `?`, `N`, Esc, Enter, Shift+Enter), held Tab (`Tab+M`) and sequences (`G→T`). The keys come from
/// [bindings] (TickTick's by default; Settings → Atalhos changes them).
class ShortcutResolver {
  ShortcutResolver([ShortcutDetector? detector]) : _detector = detector ?? ShortcutDetector() {
    bindings = ShortcutBindings.defaults;
  }

  final ShortcutDetector _detector;

  bool get isTabHeld => _detector.isTabHeld;

  final _combos = <String, ShortcutAction>{};
  final _tab = <String, ShortcutAction>{};
  final _sequences = <String, Map<String, ShortcutAction>>{};
  final _singles = <String, ShortcutAction>{};

  /// The keys of each action.
  set bindings(Map<ShortcutAction, List<String>> map) {
    _combos.clear();
    _tab.clear();
    _sequences.clear();
    _singles.clear();
    for (final e in map.entries) {
      for (final binding in e.value) {
        final n = ShortcutBindings.normalize(binding);
        if (n == null) continue;
        if (n.contains(' ')) {
          final [first, second] = n.split(' ');
          (_sequences[first] ??= {})[second] = e.key;
        } else if (n.startsWith('tab+')) {
          _tab[n.substring(4)] = e.key;
        } else if (n.length > 1 && n.contains('+')) {
          _combos[n] = e.key;
        } else {
          _singles[n] = e.key;
        }
      }
    }
    _detector.prefixes = _sequences.keys.toSet();
  }

  /// The key's name in a binding ("k", "delete", "space").
  static String keyName(LogicalKeyboardKey key) => key == LogicalKeyboardKey.space ? 'space' : key.keyLabel.toLowerCase().replaceAll(' ', '');

  ShortcutAction? resolve(KeyEvent event, {required bool control, required bool shift, required bool alt}) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      if (control || alt) {
        return _combos[[if (control) 'ctrl', if (shift) 'shift', if (alt) 'alt', keyName(key)].join('+')];
      }
      if (key == LogicalKeyboardKey.escape) return ShortcutAction.escape;
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
        return shift ? ShortcutAction.addSubtask : ShortcutAction.addTaskBelow;
      }
      // Symbols by character, so "/" and "?" work on any keyboard layout (ABNT2 included).
      final character = event.character;
      if (character != null && character.length == 1 && !RegExp('[a-zA-Z0-9]').hasMatch(character)) {
        final action = _singles[character];
        if (action != null) return action;
      }
    }
    if (control || alt) return null;
    final shortcut = _detector.handle(event);
    return switch (shortcut) {
      TabCombo(:final key) => _tab[key],
      KeySequence(:final first, :final second) => _sequences[first]?[second],
      // A single letter (such as "N") when it is not the second key of a sequence.
      null when event is KeyDownEvent && !_detector.isTabHeld => _singles[keyName(key)],
      null => null,
    };
  }
}
