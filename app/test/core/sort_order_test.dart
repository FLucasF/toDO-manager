import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/sort_order.dart';

void main() {
  group('SortOrder', () {
    test("uses TickTick's 2^40 step", () {
      expect(SortOrder.step, 1099511627776);
    });

    test('moving an item writes only its order when there is room, else reindexes', () {
      const step = SortOrder.step;
      expect(SortOrder.moved([0, step, 2 * step], 0, 2), [step, 2 * step, 3 * step]);
      expect(SortOrder.moved([0, step, 2 * step], 2, 0), [-step, 0, step]);
      expect(SortOrder.moved([0, step, 2 * step], 2, 1), [0, step ~/ 2, step]);
      expect(SortOrder.moved([0, 1, 2], 2, 1), SortOrder.reindex(3), reason: 'no integer between 0 and 1');
    });

    test('before and after an item are one step away', () {
      expect(SortOrder.before(0), -SortOrder.step);
      expect(SortOrder.after(0), SortOrder.step);
      expect(SortOrder.before(null), 0);
      expect(SortOrder.after(null), 0);
    });

    test('between two neighbours is the midpoint', () {
      expect(SortOrder.between(0, SortOrder.step), SortOrder.step ~/ 2);
      expect(SortOrder.between(-SortOrder.step, SortOrder.step), 0);
    });

    test('adjacent neighbours need a reindex', () {
      expect(SortOrder.between(10, 11), isNull);
    });

    test('allows 40 insertions at the same spot before reindexing', () {
      const previous = 0;
      var next = SortOrder.step;
      var insertions = 0;
      while (true) {
        final middle = SortOrder.between(previous, next);
        if (middle == null) break;
        next = middle;
        insertions++;
      }
      expect(insertions, 40);
    });

    test('does not overflow near the 64-bit limit', () {
      const max = 0x7FFFFFFFFFFFFFFF;
      expect(SortOrder.between(max - 4, max), max - 2);
    });

    test('rejects inverted bounds', () {
      expect(() => SortOrder.between(5, 5), throwsArgumentError);
    });

    test('reindex spaces items by the step', () {
      expect(SortOrder.reindex(3), [0, SortOrder.step, 2 * SortOrder.step]);
    });
  });
}
