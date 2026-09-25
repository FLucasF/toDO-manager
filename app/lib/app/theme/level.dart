import 'dart:ui';

/// Opacity by level, like TickTick's classes (`text-grey-60`, `bg-primary-10`): the theme's base
/// color at `level / 100` opacity.
extension TtColorLevel on Color {
  Color level(int level) {
    assert(level >= 0 && level <= 100, 'opacity level out of 0..100: $level');
    return withValues(alpha: level / 100);
  }
}
