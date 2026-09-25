import '../core/ids.dart';
import '../domain/enums.dart';
import '../domain/import/imported_task.dart';
import 'repository.dart';

/// What an import created.
class ImportResult {
  const ImportResult({required this.tasks, required this.lists});

  final int tasks;
  final int lists;
}

/// Writes tasks read from TickTick's backup or an iCal file. Folders, lists, sections and
/// tags are matched by name (ignoring case) and created when missing; "Inbox" is the Caixa de Entrada.
/// Tasks without a list go to [defaultListId]; subtasks find their parent through the file's ids.
Future<ImportResult> importTasks(Repository repo, List<ImportedTask> tasks, {String defaultListId = inboxListId}) async {
  final s = await repo.loadSnapshot();
  String key(String name) => name.trim().toLowerCase();
  final folders = {for (final f in s.activeFolders) key(f.name): f.id};
  final lists = {
    for (final l in s.lists)
      if (l.deletedAt == null) key(l.name): l.id,
  };
  final sections = {
    for (final sec in s.sections)
      if (sec.deletedAt == null) '${sec.listId}|${key(sec.name)}': sec.id,
  };
  var createdLists = 0;

  Future<String> listOf(ImportedTask t) async {
    final name = t.listName?.trim();
    if (name == null || name.isEmpty) return defaultListId;
    if (key(name) == 'inbox' || key(name) == 'caixa de entrada') return inboxListId;
    final existing = lists[key(name)];
    if (existing != null) return existing;
    String? folderId;
    final folderName = t.folderName?.trim();
    if (folderName != null && folderName.isNotEmpty) {
      folderId = folders[key(folderName)] ??= await repo.createFolder(folderName);
    }
    createdLists++;
    return lists[key(name)] = await repo.createList(name: name, folderId: folderId);
  }

  Future<String?> sectionOf(String listId, String? name) async {
    if (name == null || name.trim().isEmpty) return null;
    return sections['$listId|${key(name)}'] ??= await repo.createSection(listId, name.trim());
  }

  // Parents first, so subtasks can point to them.
  final pending = [...tasks];
  final ids = <String, String>{};
  var created = 0;
  while (pending.isNotEmpty) {
    final ready = pending
        .where((t) => t.parentSourceId == null || ids.containsKey(t.parentSourceId) || !tasks.any((o) => o.sourceId == t.parentSourceId))
        .toList();
    if (ready.isEmpty) break;
    for (final t in ready) {
      pending.remove(t);
      final listId = await listOf(t);
      final parentId = t.parentSourceId == null ? null : ids[t.parentSourceId];
      final id = await repo.createTask(
        listId: listId,
        title: t.title,
        content: t.content,
        sectionId: parentId == null ? await sectionOf(listId, t.sectionName) : null,
        parentId: parentId,
        dueDate: t.dueDate,
        startDate: t.startDate,
        isAllDay: t.isAllDay,
        priority: Priority.fromCode(t.priority),
        kind: switch (t.kind) {
          ImportedKind.note => TaskKind.note,
          ImportedKind.checklist => TaskKind.checklist,
          ImportedKind.text => TaskKind.text,
        },
        tagIds: [for (final tag in t.tags) await repo.createTag(tag)],
        repeatRule: t.repeatRule,
        reminders: t.reminders,
        atTop: false,
      );
      if (t.sourceId != null) ids[t.sourceId!] = id;
      for (final (title, done) in t.items) {
        final item = await repo.addChecklistItem(id, title: title);
        if (done) await repo.setChecklistItemCompleted(item, completed: true);
      }
      final status = switch (t.status) {
        ImportedStatus.open => TaskStatus.open,
        ImportedStatus.completed => TaskStatus.completed,
        ImportedStatus.wontDo => TaskStatus.wontDo,
      };
      if (status != TaskStatus.open || t.createdAt != null) {
        await repo.setImportedState(
          id,
          status: status,
          completedAt: status == TaskStatus.open ? null : (t.completedAt ?? t.dueDate),
          createdAt: t.createdAt,
        );
      }
      created++;
    }
  }
  return ImportResult(tasks: created, lists: createdLists);
}
