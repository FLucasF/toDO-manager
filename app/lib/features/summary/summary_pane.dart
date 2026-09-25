import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/summary.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../focus/focus_page.dart' show focusRecordsProvider;
import '../tasks/export_print.dart' show printPdf;
import '../tasks/task_actions.dart' show pickListTarget;
import '../detail/content_editor.dart';
import 'summary_text.dart';

/// "Resumo" (`#q/all/summary`): an editable report of the tasks of a period, made from the
/// filters and display options of the right panel; "Modelos" keep a configuration; Copiar and PDF.
class SummaryPane extends ConsumerStatefulWidget {
  const SummaryPane({super.key, this.isNarrow = false, this.onToggleSidebar});

  final bool isNarrow;
  final VoidCallback? onToggleSidebar;

  @override
  ConsumerState<SummaryPane> createState() => _SummaryPaneState();
}

class _SummaryPaneState extends ConsumerState<SummaryPane> {
  /// The last report generated (markdown): edits stay until the filters or the tasks change it.
  String? _generated;

  /// The report as the editor has it now, with the user's edits.
  String _edited = '';

  /// Plain text of the report for Copiar, PDF, Imagem and email.
  String get _plain => summaryPlainText(_edited);

  SummaryConfig get _config => (ref.read(preferencesProvider).value ?? Preferences.defaults).summaryConfig;

  void _set(SummaryConfig c) => unawaited(ref.read(preferencesRepositoryProvider).setSummaryConfig(c));

  Future<Set<T>?> _pickMany<T>(String title, Map<T, String> options, Set<T> selected) {
    final t = AppLocalizations.of(context);
    return showDialog<Set<T>>(
      context: context,
      builder: (context) {
        final picked = {...selected};
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            content: SizedBox(
              width: 320,
              child: ListView(
                shrinkWrap: true,
                children: [
                  CheckboxListTile(dense: true, value: picked.isEmpty, title: Text(t.searchAll), onChanged: (_) => setLocal(picked.clear)),
                  for (final o in options.entries)
                    CheckboxListTile(
                      dense: true,
                      value: picked.contains(o.key),
                      title: Text(o.value),
                      onChanged: (on) => setLocal(() => on == true ? picked.add(o.key) : picked.remove(o.key)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
              FilledButton(onPressed: () => Navigator.pop(context, picked), child: Text(t.actionOk)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveTemplate() async {
    final t = AppLocalizations.of(context);
    final name = await promptText(context, title: t.summarySaveTemplate, message: t.summarySaveTemplateHint, hint: t.summaryTemplateName);
    if (name == null || name.trim().isEmpty) return;
    final prefs = ref.read(preferencesProvider).value ?? Preferences.defaults;
    await ref.read(preferencesRepositoryProvider).setSummaryTemplates([
      for (final tpl in prefs.summaryTemplates)
        if (tpl.name != name.trim()) tpl,
      SummaryTemplate(name.trim(), _config),
    ]);
  }

  Future<void> _deleteTemplate(SummaryTemplate tpl) async {
    final prefs = ref.read(preferencesProvider).value ?? Preferences.defaults;
    await ref.read(preferencesRepositoryProvider).setSummaryTemplates([
      for (final other in prefs.summaryTemplates)
        if (other.name != tpl.name) other,
    ]);
  }

  Future<void> _pickCustomDates(SummaryConfig c) async {
    final now = ref.read(clockProvider).now();
    final range = await showDateRangePicker(context: context, firstDate: DateTime(now.year - 10), lastDate: DateTime(now.year + 10));
    if (range != null) _set(c.copyWith(date: SummaryDate.custom, from: range.start, to: range.end));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final c = prefs.summaryConfig;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final text = summaryReport(t, s, c, now, focus: focusByTask(ref.watch(focusRecordsProvider).value ?? const []), markdown: true);
    if (text != _generated) {
      _generated = text;
      _edited = text;
    }

    final dateOptions = {
      SummaryDate.today: t.dateToday,
      SummaryDate.tomorrow: t.dateTomorrow,
      SummaryDate.yesterday: t.relativeYesterday,
      SummaryDate.thisWeek: t.filterDateThisWeek,
      SummaryDate.nextWeek: t.filterDateNextWeek,
      SummaryDate.lastWeek: t.searchDateLastWeek,
      SummaryDate.thisMonth: t.filterDateThisMonth,
      SummaryDate.lastMonth: t.searchDateLastMonth,
      SummaryDate.custom: t.searchDateCustom,
    };
    final statusOptions = {
      SummaryStatus.completed: t.summaryCompleted,
      SummaryStatus.inProgress: t.summaryInProgress,
      SummaryStatus.incomplete: t.summaryIncomplete,
      SummaryStatus.wontDo: t.summaryWontDo,
    };
    final fieldOptions = {
      SummaryField.status: t.summaryFieldStatus,
      SummaryField.progress: t.summaryFieldProgress,
      SummaryField.completionTime: t.summaryFieldCompletionTime,
      SummaryField.taskTime: t.summaryFieldTaskTime,
      SummaryField.title: t.summaryFieldTitle,
      SummaryField.parent: t.summaryFieldParent,
      SummaryField.tag: t.summaryFieldTag,
      SummaryField.focus: t.summaryFieldFocus,
      SummaryField.list: t.summaryFieldList,
      SummaryField.detail: t.summaryFieldDetail,
    };
    String many<T>(Set<T> selected, Map<T, String> options, String all) =>
        selected.isEmpty ? all : [for (final v in selected) ?options[v]].join(', ');

    Widget row(String label, String value, VoidCallback onTap) => ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(
        label,
        style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: TtText.body, color: tt.text),
      ),
      trailing: Icon(Icons.expand_more, size: 16, color: tt.textTertiary),
      onTap: onTap,
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w700, color: tt.textTertiary),
      ),
    );

    final lists = {for (final l in s.activeLists) l.id: labels.listName(l)};
    final tags = {for (final tag in s.activeTags) tag.id: tag.name};
    final priorities = {for (final p in Priority.values.reversed) p: labels.priority(p)};

    final panel = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        section(t.summaryTemplates),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tpl in prefs.summaryTemplates)
                InputChip(label: Text(tpl.name), onPressed: () => _set(tpl.config), onDeleted: () => unawaited(_deleteTemplate(tpl))),
              ActionChip(avatar: const Icon(Icons.add, size: 16), label: Text(t.summarySaveTemplate), onPressed: () => unawaited(_saveTemplate())),
            ],
          ),
        ),
        section(t.summaryFilter),
        row(
          t.searchFilterDate,
          c.date == SummaryDate.custom ? summaryPeriodTitle(t, summaryRange(c, startOfDay(now))) : dateOptions[c.date]!,
          () async {
            final picked = await showDialog<SummaryDate>(
              context: context,
              builder: (context) => SimpleDialog(
                children: [
                  for (final o in dateOptions.entries)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, o.key),
                      child: Text(o.value, style: TextStyle(fontWeight: o.key == c.date ? FontWeight.w700 : null)),
                    ),
                ],
              ),
            );
            if (picked == null) return;
            if (picked == SummaryDate.custom) {
              await _pickCustomDates(c);
            } else {
              _set(c.copyWith(date: picked));
            }
          },
        ),
        row(t.searchFilterLists, many(c.listIds, lists, t.summaryAllLists), () async {
          final picked = await _pickMany(t.searchFilterLists, lists, c.listIds);
          if (picked != null) _set(c.copyWith(listIds: picked));
        }),
        row(t.searchFilterStatus, many(c.statuses, statusOptions, t.summaryAllStatuses), () async {
          final picked = await _pickMany(t.searchFilterStatus, statusOptions, c.statuses);
          if (picked != null) _set(c.copyWith(statuses: picked));
        }),
        row(t.filterFieldTag, many(c.tagIds, tags, t.summaryAllTags), () async {
          final picked = await _pickMany(t.filterFieldTag, tags, c.tagIds);
          if (picked != null) _set(c.copyWith(tagIds: picked));
        }),
        row(t.searchFilterPriority, many(c.priorities, priorities, t.summaryAllPriorities), () async {
          final picked = await _pickMany(t.searchFilterPriority, priorities, c.priorities);
          if (picked != null) _set(c.copyWith(priorities: picked));
        }),
        section(t.summaryDisplay),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<SummaryGrouping>(
            isExpanded: true,
            value: c.grouping,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: SummaryGrouping.status, child: Text(t.summaryByStatus)),
              DropdownMenuItem(value: SummaryGrouping.list, child: Text(t.summaryByList)),
              DropdownMenuItem(value: SummaryGrouping.completionDate, child: Text(t.summaryByCompletionDate)),
              DropdownMenuItem(value: SummaryGrouping.taskDate, child: Text(t.summaryByTaskDate)),
              DropdownMenuItem(value: SummaryGrouping.tag, child: Text(t.summaryByTag)),
              DropdownMenuItem(value: SummaryGrouping.priority, child: Text(t.summaryByPriority)),
            ],
            onChanged: (g) => g == null ? null : _set(c.copyWith(grouping: g)),
          ),
        ),
        for (final o in fieldOptions.entries)
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(o.value),
            value: c.fields.contains(o.key),
            onChanged: (on) => _set(c.copyWith(fields: on == true ? {...c.fields, o.key} : ({...c.fields}..remove(o.key)))),
          ),
        SwitchListTile(
          dense: true,
          title: Text(t.summaryNextPeriod),
          value: c.nextPeriod,
          onChanged: (v) => _set(c.copyWith(nextPeriod: v)),
        ),
      ],
    );

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(widget.isNarrow ? 12 : 20, 0, 12, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(8)),
            // The editable report with the formatting bar (H, B, checkbox, lists, I, U, S…).
            child: ListView(
              children: [
                ContentEditor(
                  markdown: _edited,
                  placeholder: '',
                  showFormatBar: true,
                  now: ref.read(clockProvider).now,
                  onChanged: (md) => _edited = md,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(widget.isNarrow ? 12 : 20, 0, 12, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: Text(t.summaryCopy),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _plain));
                  if (context.mounted) showToast(context, t.toastCopied);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(t.summarySavePdf),
                onPressed: () {
                  final lines = _plain.split('\n');
                  unawaited(
                    printPdf(lines.first, [for (final l in lines.skip(1)) pw.Text(l, style: const pw.TextStyle(fontSize: 12, lineSpacing: 3))]),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text(t.summarySaveImage),
                onPressed: () async {
                  final saved = await saveSummaryImage(_plain, DefaultTextStyle.of(context).style);
                  if (saved && context.mounted) showToast(context, t.summaryImageSaved);
                },
              ),
              // "Inserir numa nota": a note with the report, in the chosen list.
              OutlinedButton.icon(
                icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                label: Text(t.summaryToNote),
                onPressed: () async {
                  // The note keeps the formatting; its title is the period as plain text.
                  final text = _edited;
                  final title = _plain.split('\n').first;
                  final target = await pickListTarget(context, ref);
                  if (target == null) return;
                  final lines = text.split('\n');
                  await ref
                      .read(repositoryProvider)
                      .createTask(
                        listId: target.$1,
                        sectionId: target.$2,
                        title: title,
                        content: lines.skip(1).join('\n').trim(),
                        kind: TaskKind.note,
                      );
                  if (context.mounted) showToast(context, t.summaryNoteCreated);
                },
              ),
              // "Enviar email": a new message in the mail app, with the period as the subject.
              OutlinedButton.icon(
                icon: const Icon(Icons.mail_outline, size: 16),
                label: Text(t.summarySendEmail),
                onPressed: () async {
                  final text = _plain;
                  bool opened;
                  try {
                    opened = await launchUrl(summaryMailUri(text));
                  } on Object {
                    opened = false;
                  }
                  if (opened || !context.mounted) return;
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) showToast(context, t.summaryNoMailApp);
                },
              ),
            ],
          ),
        ),
      ],
    );

    // A Material, so the panel's tiles paint their highlight.
    return Material(
      color: tt.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 16, 10),
            child: Row(
              children: [
                if (widget.onToggleSidebar != null)
                  IconButton(
                    icon: Icon(widget.isNarrow ? Icons.menu : Icons.menu_open, color: tt.textSecondary),
                    onPressed: widget.onToggleSidebar,
                  ),
                const SizedBox(width: 4),
                Text(
                  t.smartSummary,
                  style: TextStyle(fontSize: TtText.listTitle, fontWeight: FontWeight.w600, color: tt.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.isNarrow
                ? Column(
                    children: [
                      ExpansionTile(
                        title: Text(t.summaryFilter),
                        children: [SizedBox(height: 320, child: panel)],
                      ),
                      Expanded(child: editor),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: editor),
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: tt.divider)),
                        ),
                        child: panel,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Salvar como Imagem": the report drawn on a light card, saved as a PNG where the user
/// picks. Returns whether it was saved.
/// "mailto:" with the report: its first line as the subject, the rest as the body. Spaces are %20
/// (a "+" would show up in the mail app).
Uri summaryMailUri(String report) {
  final lines = report.split('\n');
  final subject = Uri.encodeComponent(lines.first);
  final body = Uri.encodeComponent(lines.skip(1).join('\n').trim());
  return Uri.parse('mailto:?subject=$subject&body=$body');
}

Future<bool> saveSummaryImage(String text, TextStyle base) async {
  const width = 720.0, padding = 32.0;
  final lines = text.split('\n');
  final painter = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: '${lines.first}\n',
          style: base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF191919), height: 1.6),
        ),
        TextSpan(
          text: lines.skip(1).join('\n'),
          style: base.copyWith(fontSize: 15, color: const Color(0xFF333333), height: 1.6),
        ),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 2 * padding);
  final height = painter.height + 2 * padding;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);
  painter.paint(canvas, const Offset(padding, padding));
  final image = await recorder.endRecording().toImage(width.round(), height.ceil());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  if (png == null) return false;
  final bytes = png.buffer.asUint8List();
  final path = await FilePicker.platform.saveFile(fileName: 'resumo.png', bytes: bytes, type: FileType.custom, allowedExtensions: ['png']);
  // Desktop returns the chosen path; write it when the picker did not.
  if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  return path != null;
}
