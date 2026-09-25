import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/domain/views.dart';

void main() {
  // Friday, 25/09/2026; the week starts on Sunday 20/09.
  final today = DateTime(2026, 9, 25);

  test('"Todas as datas": this week, last week, this month, another month', () {
    bool on(ClosedFilter f, DateTime closed) => f.matches(closed, 'inbox', today);
    expect(on(const ClosedFilter(), DateTime(2020)), isTrue);
    expect(on(const ClosedFilter(date: ClosedDate.thisWeek), DateTime(2026, 9, 20, 8)), isTrue);
    expect(on(const ClosedFilter(date: ClosedDate.thisWeek), DateTime(2026, 9, 19, 23)), isFalse);
    expect(on(const ClosedFilter(date: ClosedDate.lastWeek), DateTime(2026, 9, 13)), isTrue);
    expect(on(const ClosedFilter(date: ClosedDate.lastWeek), DateTime(2026, 9, 20)), isFalse);
    expect(on(const ClosedFilter(date: ClosedDate.thisMonth), DateTime(2026, 9, 1)), isTrue);
    expect(on(const ClosedFilter(date: ClosedDate.thisMonth), DateTime(2026, 8, 31)), isFalse);
    final august = ClosedFilter(date: ClosedDate.otherMonth, month: DateTime(2026, 8));
    expect((on(august, DateTime(2026, 8, 31, 22)), on(august, DateTime(2026, 9, 1))), (true, false));
  });

  test('"Todas as listas": one list', () {
    const work = ClosedFilter(listId: 'work');
    expect((work.matches(today, 'work', today), work.matches(today, 'inbox', today)), (true, false));
    expect((const ClosedFilter().isDefault, work.isDefault), (true, false));
  });
}
