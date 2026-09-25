import 'package:flutter/material.dart';

import '../../data/preferences_repository.dart';

import '../../domain/enums.dart';
import 'level.dart';
import 'palette_generated.dart';

/// TickTick colors used by the widgets, derived from the extracted palette (docs/referencia) and the
/// measurements taken on the webapp (2026-09-24).
@immutable
class TtColors extends ThemeExtension<TtColors> {
  const TtColors(this.palette, {required this.isDark});

  final TtPalette palette;
  final bool isDark;

  /// Background of the sidebar, list and detail columns (dark: #1C1C1C).
  Color get screen => palette.screenBackground;

  /// Background of the left icon bar (dark: #242424).
  Color get iconBar => palette.leftSidebarBgColor;
  Color get primary => palette.primary;

  /// Main text ("grey" at full opacity: white on dark, #191919 on light).
  Color get text => palette.grey;
  Color get textSecondary => palette.grey.level(60);
  Color get textTertiary => palette.grey.level(40);
  Color get textFaint => palette.grey.level(30);
  Color get placeholder => palette.grey.level(20);

  /// Row separator and subtle fills (measured: grey 5% and 3%).
  Color get divider => palette.grey.level(5);
  Color get fieldFill => palette.grey.level(3);
  Color get hover => palette.grey.level(5);

  /// Selected sidebar item (measured: rgba(255,255,255,0.08) on dark).
  Color get selected => palette.grey.level(8);
  Color get overdue => palette.priorityHigh;

  Color priorityColor(Priority p) => switch (p) {
    Priority.high => palette.priorityHigh,
    Priority.medium => palette.priorityMedium,
    Priority.low => palette.priorityLow,
    Priority.none => palette.grey.level(40),
  };

  @override
  TtColors copyWith({TtPalette? palette, bool? isDark}) => TtColors(palette ?? this.palette, isDark: isDark ?? this.isDark);

  @override
  TtColors lerp(TtColors? other, double t) => t < 0.5 || other == null ? this : other;
}

extension TtThemeContext on BuildContext {
  TtColors get tt => Theme.of(this).extension<TtColors>()!;
}

/// Font sizes measured on the webapp.
abstract final class TtText {
  static const double body = 14;
  static const double small = 12;
  static const double listTitle = 20;
  static const double detailTitle = 19;
}

/// Layout sizes measured on the webapp.
abstract final class TtSizes {
  static const double iconBarWidth = 50;
  static const double sidebarWidth = 304;
  static const double sidebarItemHeight = 36;
  static const double sidebarHeaderHeight = 30;
  static const double rowHeight = 40;
  static const double groupHeaderHeight = 44;
  static const double checkbox = 17;
  static const double addFieldHeight = 40;
  static const double detailBarHeight = 48;
  static const double detailMinWidth = 320;

  /// Detail column width as a fraction of the window (webapp: `w-[36%]`, measured 904 of 2560).
  static const double detailFraction = 0.35;

  /// Below this width the app uses the narrow (mobile) layout.
  static const double narrowBreakpoint = 900;
  static const double subtaskIndent = 24;
}

/// Primary colors of the "Série de Cores"; null keeps the palette's. The exact values
/// of TickTick's series were not recorded, so these are close approximations.
Color? seriesPrimary(ColorSeries s) => switch (s) {
  ColorSeries.standard => null,
  ColorSeries.sky => const Color(0xFF3FA7F2),
  ColorSeries.turquoise => const Color(0xFF1FB8A6),
  ColorSeries.teal => const Color(0xFF2D8F9E),
  ColorSeries.reed => const Color(0xFF6FA05A),
  ColorSeries.yellow => const Color(0xFFE8A91B),
  ColorSeries.pinkPear => const Color(0xFFE56B8B),
  ColorSeries.lilac => const Color(0xFF9A7BDD),
  ColorSeries.ebony => const Color(0xFF5E5A57),
  ColorSeries.navy => const Color(0xFF34506F),
  ColorSeries.grey => const Color(0xFF7E8490),
};

/// [accent], a color picked in the palette, wins over the [series].
ThemeData buildTheme({required bool dark, ColorSeries series = ColorSeries.standard, Color? accent}) {
  final base_ = dark ? darkPalette : lightPalette;
  final palette = switch (accent ?? seriesPrimary(series)) {
    null => base_,
    final primary => base_.withPrimary(primary),
  };
  final colors = TtColors(palette, isDark: dark);
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    primary: palette.primary,
    onPrimary: Colors.white,
    surface: palette.screenBackground,
    onSurface: palette.grey,
    surfaceContainer: dark ? const Color(0xFF2A2A2A) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF2E2E2E) : Colors.white,
    outline: palette.grey.level(10),
    outlineVariant: palette.grey.level(5),
    error: palette.warnRed,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.screenBackground,
    canvasColor: palette.screenBackground,
    dividerColor: colors.divider,
    visualDensity: VisualDensity.compact,
    extensions: [colors],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: palette.grey, displayColor: palette.grey),
    iconTheme: IconThemeData(color: colors.textSecondary, size: 18),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: palette.primary,
        selectedForegroundColor: Colors.white,
        foregroundColor: colors.textSecondary,
        side: BorderSide(color: colors.divider),
        visualDensity: VisualDensity.compact,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(color: dark ? const Color(0xFF3A3A3A) : const Color(0xFF333333), borderRadius: BorderRadius.circular(4)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainer,
      textStyle: TextStyle(color: palette.grey, fontSize: TtText.body),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      hintStyle: TextStyle(color: colors.placeholder, fontSize: TtText.body),
      border: InputBorder.none,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF3A3A3A) : const Color(0xFF333333),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: TtText.body),
      actionTextColor: palette.primary,
      width: 360,
    ),
  );
}
