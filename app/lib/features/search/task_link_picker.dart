import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/search.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';

/// Link scheme of task links in the content: `[title](task:<id>)`. TickTick stores its webapp URL;
/// the id alone keeps working when the task changes list.
const taskLinkScheme = 'task:';

String taskLinkHref(String taskId) => '$taskLinkScheme$taskId';

String? taskIdOfHref(String href) => href.startsWith(taskLinkScheme) ? href.substring(taskLinkScheme.length) : null;

/// "[[" in the content: a list of tasks to link, filtered as you type.
Future<Task?> pickTaskToLink(BuildContext context, {String? excludeId}) => showDialog<Task>(
  context: context,
  builder: (_) => _TaskLinkPicker(excludeId: excludeId),
);

class _TaskLinkPicker extends ConsumerStatefulWidget {
  const _TaskLinkPicker({this.excludeId});

  final String? excludeId;

  @override
  ConsumerState<_TaskLinkPicker> createState() => _TaskLinkPickerState();
}

class _TaskLinkPickerState extends ConsumerState<_TaskLinkPicker> {
  final _query = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _onKey);
  int _highlighted = 0;
  List<Task> _tasks = const [];

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _tasks.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlighted = (_highlighted + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) % _tasks.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      Navigator.pop(context, _tasks[_highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    _tasks = [
      for (final hit in searchTasks(s, _query.text, filters: const SearchFilters(statuses: {TaskStatus.open, TaskStatus.completed})).take(30))
        if (hit.task.id != widget.excludeId) hit.task,
    ];
    if (_highlighted >= _tasks.length) _highlighted = 0;
    return Dialog(
      alignment: const Alignment(0, -0.5),
      child: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _query,
                focusNode: _focus,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link, size: 18),
                  hintText: t.linkPickerHint,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() => _highlighted = 0),
              ),
            ),
            const Divider(height: 1),
            // "Sem tarefas / Tente alternar listas ou pesquisar".
            if (_tasks.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.linkPickerEmptyTitle,
                        style: TextStyle(fontWeight: FontWeight.w600, color: context.tt.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.linkPickerEmptyBody,
                        style: TextStyle(fontSize: TtText.small, color: context.tt.textTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final (i, task) in _tasks.indexed)
                      InkWell(
                        onTap: () => Navigator.pop(context, task),
                        child: Container(
                          height: 36,
                          color: i == _highlighted ? tt.selected : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                task.kind == TaskKind.note ? Icons.description_outlined : Icons.check_box_outline_blank,
                                size: 16,
                                color: tt.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(task.title.isEmpty ? t.untitled : task.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (s.listById[task.listId] case final list?)
                                Text(
                                  labels.listName(list),
                                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
