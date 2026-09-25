/// Money is kept in cents (`int`), never in floating point; these read and write it as Brazilian
/// reais.
library;

/// "R$ 1.234,56" (with [symbol]) or "1.234,56"; negatives start with "-".
String formatMoney(int cents, {bool symbol = true}) {
  final digits = (cents.abs() ~/ 100).toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  final text = '$grouped,${(cents.abs() % 100).toString().padLeft(2, '0')}';
  return '${cents < 0 ? '-' : ''}${symbol ? r'R$ ' : ''}$text';
}

/// The cents typed in a field: "1.234,56", "1234,5", "1234.56", "R$ 12" or "12,". A "," or "."
/// followed by one or two digits at the end is the decimal separator; any other one groups
/// thousands. Null when it is not an amount.
int? parseMoney(String text) {
  final s = text.replaceAll(RegExp(r'[R$\s]'), '');
  if (s.isEmpty) return null;
  final decimal = RegExp(r'^(.*?)[,.](\d{1,2})$').firstMatch(s);
  var whole = (decimal?[1] ?? s).replaceAll(RegExp('[.,]'), '');
  if (whole.isEmpty) whole = '0';
  if (!RegExp(r'^\d{1,13}$').hasMatch(whole)) return null;
  return int.parse(whole) * 100 + int.parse((decimal?[2] ?? '0').padRight(2, '0'));
}

/// "10%", "12,5%": a rate kept in hundredths of a percent (1250 = 12,5%).
String formatPercent(int basisPoints) {
  final whole = basisPoints ~/ 100, rest = basisPoints.abs() % 100;
  if (rest == 0) return '$whole%';
  final decimals = rest % 10 == 0 ? '${rest ~/ 10}' : rest.toString().padLeft(2, '0');
  return '$whole,$decimals%';
}

/// A typed rate ("10", "12,5", "12.5%") in hundredths of a percent; null when it is not one.
int? parsePercent(String text) {
  final s = text.replaceAll(RegExp(r'[%\s]'), '').replaceAll(',', '.');
  final match = RegExp(r'^(\d{1,6})(?:\.(\d{1,2}))?$').firstMatch(s);
  if (match == null) return null;
  return int.parse(match[1]!) * 100 + int.parse((match[2] ?? '0').padRight(2, '0'));
}

/// [total] split in [parts] cents that add up to it; the first parts take the leftover cents
/// (R$ 100,00 in 3 = 33,34 + 33,33 + 33,33).
List<int> splitCents(int total, int parts) {
  final base = total ~/ parts, rest = total % parts;
  return [for (var i = 0; i < parts; i++) base + (i < rest ? 1 : 0)];
}
