import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/enums.dart';

void main() {
  test("priority uses TickTick's codes", () {
    expect(Priority.values.map((p) => p.code), [0, 1, 3, 5]);
    expect(Priority.fromCode(5), Priority.high);
    expect(() => Priority.fromCode(2), throwsFormatException);
  });

  test("status uses TickTick's codes", () {
    expect(TaskStatus.fromCode(-1), TaskStatus.wontDo);
    expect(TaskStatus.fromCode(2), TaskStatus.completed);
    expect(() => TaskStatus.fromCode(1), throwsFormatException);
  });

  test("kinds use TickTick's codes", () {
    expect(TaskKind.fromCode('CHECKLIST'), TaskKind.checklist);
    expect(ListKind.fromCode('NOTE'), ListKind.notes);
    expect(() => TaskKind.fromCode('TASK'), throwsFormatException);
  });
}
