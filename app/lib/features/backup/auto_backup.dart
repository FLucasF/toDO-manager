import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Daily local backups, like the ones TickTick's desktop app keeps: at most one per day, the newest
/// [keep] kept, in [dir]. They restore through the same path as "Importar backups locais".
class AutoBackup {
  AutoBackup(this.dir, {this.keep = 7});

  final Directory dir;
  final int keep;

  static final _name = RegExp(r'^tarefas_auto_(\d{4})(\d{2})(\d{2})\.zip$');

  static String _stamp(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

  /// The backups, newest first, with the day each one was made.
  List<(DateTime, File)> list() {
    if (!dir.existsSync()) return const [];
    final out = <(DateTime, File)>[];
    for (final file in dir.listSync().whereType<File>()) {
      final m = _name.firstMatch(p.basename(file.path));
      if (m == null) continue;
      out.add((DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!)), file));
    }
    return out..sort((a, b) => b.$1.compareTo(a.$1));
  }

  /// Makes today's backup with [export] unless it exists, then drops the oldest beyond [keep].
  /// Returns the new file, or null when today's was already there.
  Future<File?> runIfDue(DateTime now, Future<Uint8List> Function() export) async {
    final target = File(p.join(dir.path, 'tarefas_auto_${_stamp(now)}.zip'));
    if (target.existsSync()) return null;
    await dir.create(recursive: true);
    // Written aside and renamed, so a crash never leaves a half backup under a valid name.
    final partial = File('${target.path}.part');
    await partial.writeAsBytes(await export(), flush: true);
    await partial.rename(target.path);
    for (final (_, old) in list().skip(keep)) {
      await old.delete();
    }
    return target;
  }
}

/// Where the daily backups go; null (tests, or before `main` sets it) turns them off.
final autoBackupProvider = Provider<AutoBackup?>((ref) => null);
