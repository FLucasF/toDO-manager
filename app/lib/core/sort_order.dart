/// Manual ordering of items (tasks, lists, sections, tags) using TickTick's scheme: a 64-bit integer
/// with a 2^40 step between neighbours, and insertion between two items at the midpoint.
///
/// Dragging an item between others therefore writes only that item. When two neighbours get adjacent
/// (no integer left between them), the list needs a [reindex].
abstract final class SortOrder {
  /// Default distance between neighbouring items (1099511627776).
  static const int step = 1 << 40;

  /// Order for an item placed before [first] (or the first item of an empty list).
  static int before(int? first) => first == null ? 0 : first - step;

  /// Order for an item placed after [last] (or the first item of an empty list).
  static int after(int? last) => last == null ? 0 : last + step;

  /// Order between [previous] and [next]; `null` when no integer is left between them.
  static int? between(int previous, int next) {
    if (previous >= next) {
      throw ArgumentError('previous ($previous) must be lower than next ($next)');
    }
    // Midpoint without overflowing 64 bits.
    final middle = previous + (next - previous) ~/ 2;
    return middle == previous ? null : middle;
  }

  /// Fresh orders for [count] items, spaced by [step] starting at zero.
  static List<int> reindex(int count) => List<int>.generate(count, (i) => i * step, growable: false);

  /// Orders after dragging the item at [from] to position [to] (counted without it) of a list whose
  /// current orders are [orders]: only the moved item changes when there is room, else all of them.
  static List<int> moved(List<int> orders, int from, int to) {
    final rest = [...orders]..removeAt(from);
    final previous = to > 0 ? rest[to - 1] : null;
    final next = to < rest.length ? rest[to] : null;
    final order = switch ((previous, next)) {
      (null, null) => 0,
      (null, final int n) => before(n),
      (final int p, null) => after(p),
      (final int p, final int n) => p < n ? between(p, n) : null,
    };
    return order == null ? reindex(orders.length) : (rest..insert(to, order));
  }
}
