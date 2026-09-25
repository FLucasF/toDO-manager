import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/common/feedback.dart';

void main() {
  tearDown(ActionHistory.clear);

  test('Ctrl+Z undoes the last action once; Ctrl+Shift+Z does it again', () async {
    final log = <String>[];
    expect(await ActionHistory.undo(), isFalse, reason: 'nothing yet');
    ActionHistory.record(undo: () async => log.add('reabrir'), redo: () async => log.add('concluir'));
    expect(await ActionHistory.redo(), isFalse, reason: 'nothing was undone');
    expect(await ActionHistory.undo(), isTrue);
    expect(await ActionHistory.undo(), isFalse, reason: 'one step');
    expect(await ActionHistory.redo(), isTrue);
    expect(await ActionHistory.redo(), isFalse);
    expect(log, ['reabrir', 'concluir']);
  });
}
