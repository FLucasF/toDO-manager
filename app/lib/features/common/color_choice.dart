import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Preset colors of lists and tags, measured in the webapp's "Adicionar lista" dialog.
const presetColors = ['#FF6161', '#FFAC38', '#FFD324', '#E6EA49', '#35D870', '#4CA1FF', '#6E75F4'];

Color? parseHexColor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

/// Row of color dots: "none", the presets and the current custom color (if any).
class ColorChoice extends StatelessWidget {
  const ColorChoice({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    Widget dot(String? hex, {String? tooltip}) {
      final selected = hex == value;
      final color = parseHexColor(hex);
      return Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onChanged(hex),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color ?? Colors.transparent,
              border: Border.all(color: selected ? tt.primary : (color == null ? tt.textTertiary : Colors.transparent), width: selected ? 2 : 1),
            ),
            child: color == null ? Icon(Icons.block, size: 14, color: tt.textTertiary) : null,
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        dot(null, tooltip: t.colorNone),
        for (final c in presetColors) dot(c),
        if (value != null && !presetColors.contains(value)) dot(value),
        // The rainbow: any color.
        Tooltip(
          message: t.colorCustom,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final picked = await showColorPicker(context, initial: value);
              if (picked != null) onChanged(picked);
            },
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// "Cor personalizada": the palette to pick any color. Saturation and brightness in the square, the
/// hue on the rainbow bar, or the code typed. Returns "#RRGGBB".
Future<String?> showColorPicker(BuildContext context, {String? initial}) => showDialog<String>(
  context: context,
  builder: (_) => _ColorPickerDialog(initial: parseHexColor(initial)),
);

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({this.initial});

  final Color? initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _color = widget.initial == null ? const HSVColor.fromAHSV(1, 210, 0.7, 0.85) : HSVColor.fromColor(widget.initial!);
  late final _code = TextEditingController(text: _hex(_color.toColor()));

  static const _squareHeight = 180.0;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _set(HSVColor c) => setState(() {
    _color = c;
    _code.text = _hex(c.toColor());
  });

  void _pickInSquare(Offset at, Size size) =>
      _set(_color.withSaturation((at.dx / size.width).clamp(0.0, 1.0)).withValue(1 - (at.dy / size.height).clamp(0.0, 1.0)));

  void _pickHue(double x, double width) => _set(_color.withHue((x / width).clamp(0.0, 1.0) * 359.9));

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final color = _color.toColor();
    final pure = HSVColor.fromAHSV(1, _color.hue, 1, 1).toColor();

    Widget thumb(Color fill) => Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
      ),
    );

    return AlertDialog(
      title: Text(t.colorCustom, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Saturation → right, brightness → up.
            LayoutBuilder(
              builder: (context, box) {
                final size = Size(box.maxWidth, _squareHeight);
                return GestureDetector(
                  onPanDown: (d) => _pickInSquare(d.localPosition, size),
                  onPanUpdate: (d) => _pickInSquare(d.localPosition, size),
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(colors: [Colors.white, pure]),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                        ),
                        Positioned(left: _color.saturation * size.width - 9, top: (1 - _color.value) * size.height - 9, child: thumb(color)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // The hue, on the rainbow.
            Tooltip(
              message: t.colorHue,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  onPanDown: (d) => _pickHue(d.localPosition.dx, box.maxWidth),
                  onPanUpdate: (d) => _pickHue(d.localPosition.dx, box.maxWidth),
                  child: SizedBox(
                    height: 18,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned.fill(
                          top: 3,
                          bottom: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                colors: [
                                  for (var h = 0; h <= 360; h += 60)
                                    HSVColor.fromAHSV(1, h % 360 == 0 && h > 0 ? 359.9 : h.toDouble(), 1, 1).toColor(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(left: _color.hue / 360 * box.maxWidth - 9, child: thumb(pure)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: tt.divider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _code,
                    decoration: InputDecoration(labelText: t.colorCode, isDense: true),
                    onChanged: (text) {
                      final typed = parseHexColor(text.startsWith('#') ? text : '#$text');
                      if (typed != null) setState(() => _color = HSVColor.fromColor(typed));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _hex(_color.toColor())), child: Text(t.actionOk)),
      ],
    );
  }
}
