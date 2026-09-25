/// Google Calendar's event colors (measured on its dark theme, 25/09), in hue order. Their names are
/// the `eventColorNames` list of the ARB file, in the same order.
const eventPalette = [
  '#D85675', // Cherry blossom
  '#DA5234', // Tomato
  '#E3683E', // Tangerine
  '#DD7835', // Pumpkin
  '#E0963C', // Mango
  '#E7BA51', // Banana
  '#D8BE5E', // Citron
  '#BCC256', // Avocado
  '#85AD59', // Pistachio
  '#489160', // Basil
  '#55B080', // Sage
  '#429A8E', // Eucalyptus
  '#4B99D2', // Peacock
  '#668BE1', // Blueberry
  '#6E72C3', // Lavender
  '#AE9CCE', // Wisteria
  '#A479B1', // Amethyst
  '#A75ABA', // Grape
  '#957367', // Cocoa
  '#A5998C', // Birch
  '#7C7C7C', // Graphite
];

/// A named color (Google Calendar's event labels): tasks of this color are grouped under [name] in
/// Time Insights. A color has at most one label.
class ColorLabel {
  const ColorLabel({required this.color, required this.name});

  /// `#RRGGBB`, upper case.
  final String color;
  final String name;

  ColorLabel copyWith({String? color, String? name}) => ColorLabel(color: color ?? this.color, name: name ?? this.name);

  Map<String, Object?> toJson() => {'color': color, 'name': name};

  static ColorLabel? fromJson(Object? json) {
    if (json case {'color': final String color, 'name': final String name}) return ColorLabel(color: normalizeColor(color), name: name);
    return null;
  }

  @override
  bool operator ==(Object other) => other is ColorLabel && other.color == color && other.name == name;

  @override
  int get hashCode => Object.hash(color, name);
}

/// `#rrggbb` → `#RRGGBB`, so colors compare as text.
String normalizeColor(String color) => color.toUpperCase();

/// The label of [color], if it has one.
ColorLabel? labelOf(String? color, List<ColorLabel> labels) {
  if (color == null) return null;
  final key = normalizeColor(color);
  for (final l in labels) {
    if (l.color == key) return l;
  }
  return null;
}

/// The name shown for [color]: its label, else its palette name from [paletteNames], else [custom]
/// (a color picked in the palette).
String colorName(String color, List<ColorLabel> labels, List<String> paletteNames, {required String custom}) {
  if (labelOf(color, labels) case final label?) return label.name;
  final i = eventPalette.indexOf(normalizeColor(color));
  return i >= 0 && i < paletteNames.length ? paletteNames[i] : custom;
}
