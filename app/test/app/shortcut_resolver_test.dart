import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/shortcuts/shortcut_bindings.dart';
import 'package:task_manager/app/shortcuts/shortcut_resolver.dart';

KeyDownEvent _down(LogicalKeyboardKey key, {String? character, int ms = 0}) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: key,
  character: character,
  timeStamp: Duration(milliseconds: ms),
);

KeyUpEvent _up(LogicalKeyboardKey key, {int ms = 0}) => KeyUpEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: key,
  timeStamp: Duration(milliseconds: ms),
);

void main() {
  late ShortcutResolver r;
  setUp(() => r = ShortcutResolver());

  ShortcutAction? press(LogicalKeyboardKey key, {String? character, bool control = false, bool shift = false, bool alt = false, int ms = 0}) =>
      r.resolve(
        _down(key, character: character, ms: ms),
        control: control,
        shift: shift,
        alt: alt,
      );

  test('modifier combos', () {
    expect(press(LogicalKeyboardKey.keyK, control: true), ShortcutAction.palette);
    expect(press(LogicalKeyboardKey.keyZ, control: true), ShortcutAction.undo);
    expect(press(LogicalKeyboardKey.keyZ, control: true, shift: true), ShortcutAction.redo);
    expect(press(LogicalKeyboardKey.delete, control: true), ShortcutAction.delete);
    expect(press(LogicalKeyboardKey.digit3, alt: true), ShortcutAction.priorityHigh);
    expect(press(LogicalKeyboardKey.digit0, alt: true), ShortcutAction.priorityNone);
    expect(press(LogicalKeyboardKey.keyN, control: true), isNull, reason: 'Ctrl+N is not N');
  });

  test('single keys by character, Esc and Enter', () {
    expect(press(LogicalKeyboardKey.slash, character: '/'), ShortcutAction.search);
    expect(press(LogicalKeyboardKey.slash, character: '?', shift: true), ShortcutAction.help);
    expect(press(LogicalKeyboardKey.escape), ShortcutAction.escape);
    expect(press(LogicalKeyboardKey.enter), ShortcutAction.addTaskBelow);
    expect(press(LogicalKeyboardKey.enter, shift: true), ShortcutAction.addSubtask);
    expect(press(LogicalKeyboardKey.keyN), ShortcutAction.addTask);
  });

  test('held Tab and sequences', () {
    r.resolve(_down(LogicalKeyboardKey.tab), control: false, shift: false, alt: false);
    expect(press(LogicalKeyboardKey.keyM), ShortcutAction.complete);
    expect(press(LogicalKeyboardKey.digit2), ShortcutAction.tomorrow);
    expect(press(LogicalKeyboardKey.keyN), ShortcutAction.addTask, reason: 'Tab+N');
    r.resolve(_up(LogicalKeyboardKey.tab), control: false, shift: false, alt: false);

    expect(press(LogicalKeyboardKey.keyG, ms: 0), isNull);
    expect(press(LogicalKeyboardKey.keyN, ms: 200), ShortcutAction.goNext7Days, reason: 'G→N is not "add task"');
    expect(press(LogicalKeyboardKey.keyG, ms: 1000), isNull);
    expect(press(LogicalKeyboardKey.keyI, ms: 1100), ShortcutAction.goInbox);
    expect(press(LogicalKeyboardKey.keyG, ms: 2000), isNull);
    expect(press(LogicalKeyboardKey.keyX, ms: 2100), isNull, reason: 'unknown sequence');
  });

  test('changed bindings: a new sequence, a combo, and an action with no keys', () {
    r.bindings = ShortcutBindings.merged({
      'goToday': ['H J'],
      'palette': ['Ctrl+Shift+Space'],
      'addTask': [],
    });
    expect(press(LogicalKeyboardKey.keyH, ms: 0), isNull);
    expect(press(LogicalKeyboardKey.keyJ, ms: 100), ShortcutAction.goToday);
    expect(press(LogicalKeyboardKey.keyG, ms: 1000), isNull);
    expect(press(LogicalKeyboardKey.keyT, ms: 1100), isNull, reason: 'G→T is free now');
    expect(press(LogicalKeyboardKey.space, control: true, shift: true), ShortcutAction.palette);
    expect(press(LogicalKeyboardKey.keyK, control: true), isNull);
    expect(press(LogicalKeyboardKey.keyN, ms: 5000), isNull);
    expect(ShortcutBindings.display('ctrl+shift+p'), 'Ctrl+Shift+P');
    expect(ShortcutBindings.display('g t'), 'G→T');
    expect(ShortcutBindings.normalize('Shift+Ctrl+P'), 'ctrl+shift+p');
    expect(ShortcutBindings.normalize('Tab+Ctrl+P'), isNull);
  });
}
