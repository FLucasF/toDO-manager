import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/ids.dart';

/// Attachment files, kept next to the database under `attachments/<id>/<name>`. The
/// content refers to them as `![file](<id>/<name>)`, TickTick's markdown.
class AttachmentStore {
  AttachmentStore(this.root);

  final Directory root;

  /// Copies [source] into the store and returns its `<id>/<name>` reference.
  Future<String> add(File source) async {
    final id = newId();
    final name = p.basename(source.path);
    final target = File(p.join(root.path, id, name));
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return '$id/$name';
  }

  /// The file of a reference, or null for references that would leave the store.
  File? fileOf(String reference) {
    final parts = reference.split('/');
    if (parts.length != 2 || parts.any((x) => x.isEmpty || x == '..' || x == '.')) return null;
    return File(p.join(root.path, parts[0], parts[1]));
  }

  /// "86 B", "1,2 KB", "3,4 MB" (decimal comma, as the rest of the PT-BR app); empty when missing.
  String describeSize(String reference) {
    final file = fileOf(reference);
    if (file == null || !file.existsSync()) return '';
    return formatSize(file.lengthSync());
  }

  static String formatSize(int bytes) {
    String one(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${one(bytes / 1024)} KB';
    return '${one(bytes / (1024 * 1024))} MB';
  }

  /// Every stored file with its reference (for backups).
  Iterable<(String, File)> all() sync* {
    if (!root.existsSync()) return;
    for (final dir in root.listSync().whereType<Directory>()) {
      for (final file in dir.listSync().whereType<File>()) {
        yield ('${p.basename(dir.path)}/${p.basename(file.path)}', file);
      }
    }
  }

  /// Writes a file back from a backup.
  Future<void> restore(String reference, List<int> bytes) async {
    final file = fileOf(reference);
    if (file == null) return;
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<void> clear() async {
    if (root.existsSync()) await root.delete(recursive: true);
  }
}
