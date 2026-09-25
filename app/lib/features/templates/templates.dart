import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../data/repository.dart';
import '../../domain/enums.dart';
import '../../domain/quick_add.dart' show foldForSearch;
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';

final templatesProvider = StreamProvider<List<TaskTemplate>>((ref) => ref.watch(repositoryProvider).watchTemplates());

/// The templates TickTick ships with, created once on the first run. Their texts come
/// from the localizations; the exact contents in TickTick were not recorded.
Future<void> seedBuiltInTemplates(Repository repo, PreferencesRepository prefs, AppLocalizations t) async {
  if (!await prefs.builtInTemplatesSeeded()) {
    await repo.createTemplate(name: t.templateBeforeWorkName, kind: TaskKind.checklist, items: t.templateBeforeWorkItems.split('\n'));
    await repo.createTemplate(name: t.templateDailyRecordName, content: t.templateDailyRecordContent);
    await repo.createTemplate(name: t.templateTravelName, kind: TaskKind.checklist, items: t.templateTravelItems.split('\n'));
    await prefs.markBuiltInTemplatesSeeded();
  }
  // "Modelo de nota": Revisão Semanal, Nota de leitura, Nota de Reunião.
  if (!await prefs.noteTemplatesSeeded()) {
    await repo.createTemplate(name: t.templateWeeklyReviewName, kind: TaskKind.note, content: t.templateWeeklyReviewContent);
    await repo.createTemplate(name: t.templateReadingName, kind: TaskKind.note, content: t.templateReadingContent);
    await repo.createTemplate(name: t.templateMeetingName, kind: TaskKind.note, content: t.templateMeetingContent);
    await prefs.markNoteTemplatesSeeded();
  }
}

/// "Salvar como modelo": name pre-filled with the title; toast "Salvo".
Future<void> saveAsTemplate(BuildContext context, WidgetRef ref, Task task) async {
  final t = AppLocalizations.of(context);
  final name = TextEditingController(text: task.title);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.templateSave, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.templateSaveHint,
              style: TextStyle(color: context.tt.textSecondary, fontSize: TtText.small),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(hintText: t.templateNameHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionOk)),
      ],
    ),
  );
  final text = name.text.trim();
  name.dispose();
  if (ok != true || text.isEmpty) return;
  await ref.read(repositoryProvider).saveTaskAsTemplate(task.id, text);
  if (context.mounted) showToast(context, t.toastSaved);
}

/// A template as markdown for "/ Adicionar a partir do modelo": its content, then its checklist items
/// as checkboxes.
String templateAsMarkdown(TaskTemplate template) {
  final items = [
    for (final line in template.items.split('\n'))
      if (line.trim().isNotEmpty) '- [ ] ${line.trim()}',
  ];
  return [if (template.content.trim().isNotEmpty) template.content.trim(), if (items.isNotEmpty) items.join('\n')].join('\n\n');
}

/// "Modelo de tarefa": search, cards with a preview of the content or checklist, and the
/// "Gerenciar modelo" link. Returns the chosen template.
/// [notes] opens on "Modelo de nota".
Future<TaskTemplate?> pickTemplate(BuildContext context, {bool notes = false}) => showDialog<TaskTemplate>(
  context: context,
  builder: (_) => _TemplatePicker(notes: notes),
);

class _TemplatePicker extends ConsumerStatefulWidget {
  const _TemplatePicker({this.notes = false});

  final bool notes;

  @override
  ConsumerState<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends ConsumerState<_TemplatePicker> {
  final _query = TextEditingController();

  /// "Modelo de tarefa ▾" / "Modelo de nota".
  late bool _notes = widget.notes;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final q = foldForSearch(_query.text.trim());
    final templates = [
      for (final template in ref.watch(templatesProvider).value ?? const <TaskTemplate>[])
        if ((template.kind == TaskKind.note) == _notes &&
            (q.isEmpty || foldForSearch('${template.name} ${template.content} ${template.items}').contains(q)))
          template,
    ];
    return Dialog(
      child: SizedBox(
        width: 640,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PopupMenuButton<bool>(
                        tooltip: '',
                        onSelected: (v) => setState(() => _notes = v),
                        itemBuilder: (_) => [
                          CheckedPopupMenuItem(value: false, checked: !_notes, child: Text(t.templatePickerTitle)),
                          CheckedPopupMenuItem(value: true, checked: _notes, child: Text(t.templateNotesTitle)),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _notes ? t.templateNotesTitle : t.templatePickerTitle,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tt.text),
                            ),
                            Icon(Icons.expand_more, size: 18, color: tt.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
                ],
              ),
              TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: t.searchHint,
                  filled: true,
                  fillColor: tt.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: templates.isEmpty
                    ? Center(
                        child: Text(t.templateEmpty, style: TextStyle(color: tt.textTertiary)),
                      )
                    : GridView.extent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.9,
                        children: [
                          for (final template in templates) _TemplateCard(template: template, onTap: () => Navigator.pop(context, template)),
                        ],
                      ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => unawaited(_manage(context)), child: Text(t.templateManage)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Gerenciar modelo": rename or delete.
  Future<void> _manage(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final t = AppLocalizations.of(context);
        final repo = ref.read(repositoryProvider);
        final templates = ref.watch(templatesProvider).value ?? const <TaskTemplate>[];
        return AlertDialog(
          title: Text(t.templateManage, style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final template in templates)
                  ListTile(
                    dense: true,
                    title: Text(template.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: t.actionRename,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () async {
                            final name = await promptText(context, title: t.actionRename, initial: template.name);
                            if (name != null && name.trim().isNotEmpty) await repo.renameTemplate(template.id, name);
                          },
                        ),
                        IconButton(
                          tooltip: t.shortcutDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => unawaited(repo.deleteTemplate(template.id)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
        );
      },
    ),
  );
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final TaskTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final items = template.items.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final preview = template.kind == TaskKind.checklist
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 12, color: tt.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: tt.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        : Text(
            template.content.replaceAll(RegExp(r'[*_#>`]'), ''),
            maxLines: 7,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: tt.textSecondary),
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tt.fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tt.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w600, color: tt.text, fontSize: TtText.body),
            ),
            const SizedBox(height: 8),
            Expanded(child: ClipRect(child: preview)),
          ],
        ),
      ),
    );
  }
}
