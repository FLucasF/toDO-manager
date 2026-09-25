import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../domain/task_export.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';

String? _dateLabel(AppLocalizations t, Task task, DateTime now) {
  final due = task.dueDate?.toLocal();
  if (due == null) return null;
  final dates = DateLabels(t);
  final today = startOfDay(now);
  return task.hasDuration
      ? dates.detailRange(task.startLocal!, due, isAllDay: task.isAllDay, today: today)
      : dates.detailDate(due, isAllDay: task.isAllDay, today: today);
}

/// "Export": tabs Markdown / Plain Text, the preview, "Copiar" and "Baixar".
Future<void> showExportDialog(BuildContext context, WidgetRef ref, Task task) => showDialog<void>(
  context: context,
  builder: (_) => _ExportDialog(task: task),
);

class _ExportDialog extends ConsumerStatefulWidget {
  const _ExportDialog({required this.task});

  final Task task;

  @override
  ConsumerState<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<_ExportDialog> {
  bool _markdown = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final task = s.taskById[widget.task.id] ?? widget.task;
    final text = exportTask(s, task, markdown: _markdown, dateLabel: _dateLabel(t, task, ref.read(clockProvider).now()), untitled: t.untitled);
    return AlertDialog(
      title: Text(t.menuExport, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 480,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(t.exportMarkdown)),
                ButtonSegment(value: false, label: Text(t.exportPlainText)),
              ],
              selected: {_markdown},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _markdown = v.first),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tt.fieldFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tt.divider),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: TextStyle(color: tt.text, fontSize: TtText.body, height: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) showToast(context, t.toastCopied);
          },
          child: Text(t.exportCopy),
        ),
        FilledButton(onPressed: () => unawaited(_download(text, task)), child: Text(t.exportDownload)),
      ],
    );
  }

  Future<void> _download(String text, Task task) async {
    final bytes = utf8.encode(text);
    final name = '${_safeName(task.title)}.${_markdown ? 'md' : 'txt'}';
    final path = await FilePicker.platform.saveFile(fileName: name, bytes: bytes);
    // Desktop returns the chosen path; write it when the picker did not.
    if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  }
}

String _safeName(String title) {
  final cleaned = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  return cleaned.isEmpty ? 'tarefa' : (cleaned.length > 60 ? cleaned.substring(0, 60) : cleaned);
}

/// The PDF of a printout: the title and [body].
Future<List<int>> buildPdf(String title, List<pw.Widget> body) {
  final doc = pw.Document(title: title);
  doc.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        ...body,
      ],
    ),
  );
  return doc.save();
}

/// "Imprimir" (Ctrl+P): a PDF opened in the system viewer, where it is printed.
Future<void> printPdf(String title, List<pw.Widget> body) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, '${_safeName(title)}.pdf'));
  await file.writeAsBytes(await buildPdf(title, body));
  await OpenFilex.open(file.path);
}

/// Prints one task: date, tags, content, checklist and subtasks.
Future<void> printTask(WidgetRef ref, AppLocalizations t, Task task) {
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final text = exportTask(s, task, markdown: false, dateLabel: _dateLabel(t, task, ref.read(clockProvider).now()), untitled: t.untitled);
  // The PDF's standard font has no ballot boxes.
  final lines = text.split('\n').skip(1).map((l) => l.replaceAll('☐', '[ ]').replaceAll('☑', '[x]'));
  return printPdf(task.title.isEmpty ? t.untitled : task.title, [
    for (final l in lines) pw.Text(l, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
  ]);
}

/// Prints the visible list: its groups with their tasks, subtasks indented, and the dates.
Future<void> printView(WidgetRef ref, AppLocalizations t, String title, ViewContent view) {
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final now = ref.read(clockProvider).now();
  final labels = Labels(t);
  final body = <pw.Widget>[];
  for (final g in view.groups) {
    if (g.rows.isEmpty) continue;
    final header = labels.header(g.header, s, now);
    if (header.isNotEmpty) {
      body.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(header, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
      );
    }
    for (final r in g.rows) {
      final date = _dateLabel(t, r.task, now);
      final box = r.task.status == TaskStatus.open ? '[ ]' : '[x]';
      body.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(left: 16.0 * r.depth, bottom: 3),
          child: pw.Text(
            '$box ${r.task.title.isEmpty ? t.untitled : r.task.title}${date == null ? '' : '   $date'}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      );
    }
  }
  return printPdf(title, body);
}
