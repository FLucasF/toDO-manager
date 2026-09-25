import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/shortcuts/shortcut_detector.dart';

KeyDownEvent down(LogicalKeyboardKey l, PhysicalKeyboardKey p, int ms) => KeyDownEvent(
  physicalKey: p,
  logicalKey: l,
  timeStamp: Duration(milliseconds: ms),
);

KeyUpEvent up(LogicalKeyboardKey l, PhysicalKeyboardKey p, int ms) => KeyUpEvent(
  physicalKey: p,
  logicalKey: l,
  timeStamp: Duration(milliseconds: ms),
);

void main() {
  late ShortcutDetector d;
  setUp(() => d = ShortcutDetector());

  const g = (LogicalKeyboardKey.keyG, PhysicalKeyboardKey.keyG);
  const t = (LogicalKeyboardKey.keyT, PhysicalKeyboardKey.keyT);
  const v = (LogicalKeyboardKey.keyV, PhysicalKeyboardKey.keyV);
  const k = (LogicalKeyboardKey.keyK, PhysicalKeyboardKey.keyK);
  const n = (LogicalKeyboardKey.keyN, PhysicalKeyboardKey.keyN);
  const tab = (LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);

  test('G then T is the G→T sequence', () {
    expect(d.handle(down(g.$1, g.$2, 0)), isNull);
    expect(d.handle(down(t.$1, t.$2, 300)), const KeySequence('g', 't'));
  });

  test('V then K is V→K', () {
    d.handle(down(v.$1, v.$2, 0));
    expect(d.handle(down(k.$1, k.$2, 100)), const KeySequence('v', 'k'));
  });

  test('a second key after the window is not a sequence', () {
    d.handle(down(g.$1, g.$2, 0));
    expect(d.handle(down(t.$1, t.$2, 2000)), isNull);
  });

  test('G then G is G→G (Trash)', () {
    d.handle(down(g.$1, g.$2, 0));
    expect(d.handle(down(g.$1, g.$2, 200)), const KeySequence('g', 'g'));
  });

  test('held Tab plus N is Tab+N', () {
    d.handle(down(tab.$1, tab.$2, 0));
    expect(d.handle(down(n.$1, n.$2, 50)), const TabCombo('n'));
    expect(d.tabWasModifier, isTrue);
    d.handle(up(tab.$1, tab.$2, 100));
    expect(d.isTabHeld, isFalse);
  });

  test('N alone is not a detector shortcut (plain N is handled elsewhere)', () {
    expect(d.handle(down(n.$1, n.$2, 0)), isNull);
  });

  test('Tab alone is not a modifier', () {
    d.handle(down(tab.$1, tab.$2, 0));
    d.handle(up(tab.$1, tab.$2, 80));
    expect(d.tabWasModifier, isFalse);
  });
}
