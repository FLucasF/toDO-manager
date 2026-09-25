import 'package:flutter/services.dart';

/// A recognized shortcut.
sealed class Shortcut {
  const Shortcut();
}

/// Two-key sequence, such as `G` then `T`.
final class KeySequence extends Shortcut {
  const KeySequence(this.first, this.second);

  final String first;
  final String second;

  @override
  bool operator ==(Object other) => other is KeySequence && other.first == first && other.second == second;

  @override
  int get hashCode => Object.hash(first, second);

  @override
  String toString() => '${first.toUpperCase()}→${second.toUpperCase()}';
}

/// Key pressed while Tab is held, such as `Tab+N`.
final class TabCombo extends Shortcut {
  const TabCombo(this.key);

  final String key;

  @override
  bool operator ==(Object other) => other is TabCombo && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Tab+${key.toUpperCase()}';
}

/// Recognizes TickTick's keyboard shortcuts from key events.
///
/// - Sequences: the first key ([prefixes]) arms the detector; the second must arrive within [window].
///   The survey showed TickTick ignores keys pressed with no gap; the clone accepts both.
/// - Held Tab: while Tab is down, the next letter/digit becomes `Tab+X`.
///
/// Uses the events' `timeStamp`, so it is testable without a real clock.
class ShortcutDetector {
  ShortcutDetector({this.prefixes = const {'g', 'v'}, this.window = const Duration(milliseconds: 1500)});

  /// First keys of the sequences (changed when the bindings change).
  Set<String> prefixes;
  final Duration window;

  String? _prefix;
  Duration? _prefixAt;
  bool _tabHeld = false;
  bool _tabUsed = false;

  /// Whether Tab is held right now (the app decides whether Tab should move focus).
  bool get isTabHeld => _tabHeld;

  /// Whether the last Tab press acted as a modifier (so it must not insert a tab nor move focus).
  bool get tabWasModifier => _tabUsed;

  /// Processes an event and returns the completed shortcut, or `null` when there is none yet.
  Shortcut? handle(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (event is KeyDownEvent) {
        _tabHeld = true;
        _tabUsed = false;
      } else if (event is KeyUpEvent) {
        _tabHeld = false;
      }
      return null;
    }
    if (event is! KeyDownEvent) return null;

    final key = _letterOrDigit(event.logicalKey);
    if (key == null) {
      _prefix = null;
      return null;
    }

    if (_tabHeld) {
      _tabUsed = true;
      _prefix = null;
      return TabCombo(key);
    }

    final prefix = _prefix;
    final prefixAt = _prefixAt;
    _prefix = null;
    if (prefix != null && prefixAt != null && event.timeStamp - prefixAt <= window) {
      return KeySequence(prefix, key);
    }
    if (prefixes.contains(key)) {
      _prefix = key;
      _prefixAt = event.timeStamp;
    }
    return null;
  }

  static String? _letterOrDigit(LogicalKeyboardKey key) {
    final label = key.keyLabel;
    if (label.length != 1) return null;
    final c = label.toLowerCase();
    return RegExp('[a-z0-9]').hasMatch(c) ? c : null;
  }
}
