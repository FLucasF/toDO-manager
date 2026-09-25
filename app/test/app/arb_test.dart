import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the ARB has no repeated keys (a repeat silently replaces the first text)', () {
    final raw = File('lib/l10n/app_pt.arb').readAsStringSync();
    // Top-level keys are indented by two spaces; placeholder names live deeper, inside "@key" objects.
    final keys = RegExp(r'^  "([^"]+)"\s*:', multiLine: true).allMatches(raw).map((m) => m.group(1)!).toList();
    final repeated = {for (final k in keys) k: keys.where((x) => x == k).length}..removeWhere((_, n) => n == 1);
    expect(keys, isNotEmpty);
    expect(repeated, isEmpty);
  });
}
