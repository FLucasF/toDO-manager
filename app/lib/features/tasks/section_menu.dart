import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/sort_order.dart';
import '../../data/db/database.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';

/// Menu "…" of a section: Renomear, a new section beside it (to the left / right
/// of a Kanban column, above / below in the List view), Mover para › another list, Deletar.
Future<void> showSectionMenu(BuildContext context, WidgetRef ref, Section section, {required RelativeRect position, bool columns = false}) async {
  final t = AppLocalizations.of(context);
  final repo = ref.read(repositoryProvider);
  final picked = await showMenu<String>(
    context: context,
    position: position,
    items: [
      PopupMenuItem(value: 'rename', height: 36, child: Text(t.actionRename)),
      PopupMenuItem(value: 'before', height: 36, child: Text(columns ? t.sectionAddLeft : t.sectionInsertAbove)),
      PopupMenuItem(value: 'after', height: 36, child: Text(columns ? t.sectionAddRight : t.sectionInsertBelow)),
      PopupMenuItem(value: 'move', height: 36, child: Text('${t.menuMoveTo} ›')),
      PopupMenuItem(value: 'delete', height: 36, child: Text(t.menuDelete)),
    ],
  );
  if (!context.mounted || picked == null) return;
  switch (picked) {
    case 'rename':
      final name = await promptText(context, title: t.actionRename, initial: section.name);
      if (name != null && name.trim().isNotEmpty) await repo.renameSection(section.id, name);
    case 'before' || 'after':
      final name = await promptText(context, title: t.sectionAdd, hint: t.sectionNew);
      if (name == null || name.trim().isEmpty) return;
      final sections = ref.read(snapshotProvider).value?.sectionsOf(section.listId) ?? const <Section>[];
      final i = sections.indexWhere((x) => x.id == section.id);
      final before = picked == 'before';
      final neighbour = before ? (i > 0 ? sections[i - 1] : null) : (i + 1 < sections.length ? sections[i + 1] : null);
      final order = switch ((before, neighbour)) {
        (true, null) => SortOrder.before(section.sortOrder),
        (true, final Section n) => SortOrder.between(n.sortOrder, section.sortOrder),
        (false, null) => SortOrder.after(section.sortOrder),
        (false, final Section n) => SortOrder.between(section.sortOrder, n.sortOrder),
      };
      await repo.createSection(section.listId, name, sortOrder: order);
    case 'move':
      final listId = await _pickList(context, ref, exclude: section.listId);
      if (listId != null) await repo.moveSectionToList(section.id, listId);
    case 'delete':
      await repo.deleteSection(section.id);
  }
}

/// "Mover para ›": another task list (the section's tasks go with it).
Future<String?> _pickList(BuildContext context, WidgetRef ref, {required String exclude}) {
  final t = AppLocalizations.of(context);
  final labels = Labels(t);
  final lists = [
    for (final l in (ref.read(snapshotProvider).value ?? Snapshot.empty()).activeLists)
      if (l.id != exclude) l,
  ];
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.menuMoveTo, style: const TextStyle(fontSize: 15)),
      children: [
        for (final l in lists)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, l.id),
            child: Row(
              children: [
                Text(l.emoji ?? '•'),
                const SizedBox(width: 10),
                Expanded(child: Text(labels.listName(l))),
              ],
            ),
          ),
      ],
    ),
  );
}
