import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Small charts of the statistics, drawn by hand: no chart package for a few lines.

TextPainter _text(String s, TextStyle style) => TextPainter(
  text: TextSpan(text: s, style: style),
  textDirection: TextDirection.ltr,
  maxLines: 1,
)..layout();

/// A curve over labeled points ("Curva de conclusão recente").
class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.values, required this.labels, this.format, this.height = 150, this.maxValue});

  final List<double> values;
  final List<String> labels;

  /// Text over each point; none when null.
  final String Function(double)? format;
  final double height;

  /// Top of the scale; the largest value when null.
  final double? maxValue;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(
          values: values,
          labels: labels,
          format: format,
          maxValue: maxValue,
          color: tt.primary,
          grid: tt.divider,
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 10, color: tt.textTertiary),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.values,
    required this.labels,
    required this.format,
    required this.maxValue,
    required this.color,
    required this.grid,
    required this.style,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double)? format;
  final double? maxValue;
  final Color color;
  final Color grid;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const bottom = 18.0, top = 16.0;
    final chartHeight = size.height - bottom - top;
    final top_ = maxValue ?? values.reduce(math.max);
    final scale = top_ <= 0 ? 1.0 : top_;
    final step = size.width / values.length;
    final gridPaint = Paint()..color = grid;
    for (var i = 0; i <= 2; i++) {
      final y = top + chartHeight * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final points = [for (var i = 0; i < values.length; i++) Offset(step * i + step / 2, top + chartHeight * (1 - values[i] / scale))];
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..addPolygon(points, false), line);
    final dot = Paint()..color = color;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, dot);
      if (format case final f?) {
        final label = _text(f(values[i]), style);
        label.paint(canvas, Offset(points[i].dx - label.width / 2, points[i].dy - label.height - 3));
      }
      final x = _text(labels[i], style);
      x.paint(canvas, Offset(points[i].dx - x.width / 2, size.height - x.height));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.labels != labels || old.color != color;
}

/// Vertical bars ("Tendências").
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, this.height = 150, this.format, this.highlight});

  final List<double> values;
  final List<String> labels;
  final double height;
  final String Function(double)? format;

  /// Index drawn in the primary color (the others fainter).
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarPainter(
          values: values,
          labels: labels,
          format: format,
          highlight: highlight,
          color: tt.primary,
          grid: tt.divider,
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 10, color: tt.textTertiary),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.values,
    required this.labels,
    required this.format,
    required this.highlight,
    required this.color,
    required this.grid,
    required this.style,
  });

  final List<double> values;
  final List<String> labels;
  final String Function(double)? format;
  final int? highlight;
  final Color color;
  final Color grid;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const bottom = 18.0, top = 16.0;
    final chartHeight = size.height - bottom - top;
    final maxValue = values.reduce(math.max);
    final scale = maxValue <= 0 ? 1.0 : maxValue;
    final step = size.width / values.length;
    final barWidth = math.min(28.0, step * 0.6);
    canvas.drawLine(Offset(0, top + chartHeight), Offset(size.width, top + chartHeight), Paint()..color = grid);
    for (var i = 0; i < values.length; i++) {
      final h = chartHeight * values[i] / scale;
      final x = step * i + (step - barWidth) / 2;
      final paint = Paint()..color = highlight == null || highlight == i ? color : color.withValues(alpha: 0.45);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, top + chartHeight - h, barWidth, h),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        paint,
      );
      if (format case final f? when values[i] > 0) {
        final label = _text(f(values[i]), style);
        label.paint(canvas, Offset(x + barWidth / 2 - label.width / 2, top + chartHeight - h - label.height - 2));
      }
      final l = _text(labels[i], style);
      l.paint(canvas, Offset(step * i + step / 2 - l.width / 2, size.height - l.height));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.values != values || old.labels != labels || old.highlight != highlight;
}

/// A ring split into colored parts ("Distribuição da taxa de conclusão").
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.parts, this.size = 120, this.center});

  final List<(double, Color)> parts;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _DonutPainter(parts: parts, empty: context.tt.divider),
      child: Center(child: center),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.parts, required this.empty});

  final List<(double, Color)> parts;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(10);
    final total = parts.fold(0.0, (sum, p) => sum + p.$1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    if (total <= 0) {
      canvas.drawArc(ring, 0, 2 * math.pi, false, paint..color = empty);
      return;
    }
    var start = -math.pi / 2;
    for (final (value, color) in parts) {
      final sweep = 2 * math.pi * value / total;
      canvas.drawArc(ring, start, sweep, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.parts != parts;
}

/// A grid of cells shaded by value ("Tempo mais concentrado", the annual grid). [values] are rows of
/// columns; [levelOf] turns a value into 0 (empty) … 4 (strongest).
class HeatGrid extends StatelessWidget {
  const HeatGrid({
    super.key,
    required this.values,
    required this.levelOf,
    this.cell = 12,
    this.gap = 2,
    this.rowLabels = const [],
    this.colLabels = const {},
  });

  final List<List<double>> values;
  final int Function(double) levelOf;
  final double cell;
  final double gap;

  /// Labels on the left of some rows.
  final List<String> rowLabels;

  /// Labels over some columns (column index → text).
  final Map<int, String> colLabels;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final style = DefaultTextStyle.of(context).style.copyWith(fontSize: 9, color: tt.textTertiary);
    const labelWidth = 26.0, labelHeight = 14.0;
    final cols = values.isEmpty ? 0 : values.first.length;
    return SizedBox(
      width: labelWidth + cols * (cell + gap),
      height: labelHeight + values.length * (cell + gap),
      child: CustomPaint(
        painter: _HeatPainter(
          values: values,
          levelOf: levelOf,
          cell: cell,
          gap: gap,
          color: tt.primary,
          empty: tt.fieldFill,
          style: style,
          rowLabels: rowLabels,
          colLabels: colLabels,
          labelWidth: labelWidth,
          labelHeight: labelHeight,
        ),
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  const _HeatPainter({
    required this.values,
    required this.levelOf,
    required this.cell,
    required this.gap,
    required this.color,
    required this.empty,
    required this.style,
    required this.rowLabels,
    required this.colLabels,
    required this.labelWidth,
    required this.labelHeight,
  });

  final List<List<double>> values;
  final int Function(double) levelOf;
  final double cell;
  final double gap;
  final Color color;
  final Color empty;
  final TextStyle style;
  final List<String> rowLabels;
  final Map<int, String> colLabels;
  final double labelWidth;
  final double labelHeight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in colLabels.entries) {
      _text(e.value, style).paint(canvas, Offset(labelWidth + e.key * (cell + gap), 0));
    }
    for (var r = 0; r < values.length; r++) {
      if (r < rowLabels.length && rowLabels[r].isNotEmpty) {
        final l = _text(rowLabels[r], style);
        l.paint(canvas, Offset(0, labelHeight + r * (cell + gap) + (cell - l.height) / 2));
      }
      for (var c = 0; c < values[r].length; c++) {
        final level = levelOf(values[r][c]);
        final paint = Paint()..color = level <= 0 ? empty : color.withValues(alpha: 0.2 + 0.2 * level);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(labelWidth + c * (cell + gap), labelHeight + r * (cell + gap), cell, cell), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) => old.values != values;
}
