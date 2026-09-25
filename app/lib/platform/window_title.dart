import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Title of the Windows window, through the runner's "tarefas/window" channel (see
/// windows/runner/flutter_window.cpp). Does nothing on other platforms and in tests.
class WindowTitle {
  static const _channel = MethodChannel('tarefas/window');

  String? _last;

  bool get _available => !kIsWeb && Platform.isWindows && !Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> set(String title) async {
    if (!_available || title == _last) return;
    _last = title;
    try {
      await _channel.invokeMethod<void>('setTitle', title);
    } on Object catch (e) {
      debugPrint('Window title not set: $e');
    }
  }
}
