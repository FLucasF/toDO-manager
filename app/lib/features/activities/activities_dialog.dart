import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';

/// "Atividades da tarefa": what happened to the task, by day, newest first.
Future<void> showTaskActivities(BuildContext context, String taskId) => showDialog<void>(
  context: context,
  builder: (_) => _ActivitiesDialog(taskId: taskId),
);

/// "Atividades da lista": the list's own changes and those of its tasks.
Future<void> showListActivities(BuildContext context, String listId) => showDialog<void>(
  context: context,
  builder: (_) => _ActivitiesDialog(listId: listId),
);

/// The sentence of an entry ("Você concluiu a tarefa").
String activityText(AppLocalizations t, Activity a, Snapshot s, DateTime today) {
  final labels = Labels(t);
  final dates = DateLabels(t);
  return switch (a.action) {
    ActivityAction.created => t.activityCreated,
    ActivityAction.completed => t.activityCompleted,
    ActivityAction.reopened => t.activityReopened,
    ActivityAction.wontDo => t.activityWontDo,
    ActivityAction.deleted => t.activityDeleted,
    ActivityAction.restored => t.activityRestored,
    ActivityAction.title => t.activityTitle(a.detail),
    ActivityAction.content => t.activityContent,
    ActivityAction.date => switch (a.detail.split('|')) {
      [final iso, final allDay] when DateTime.tryParse(iso) != null => t.activityDate(
        dates.detailDate(DateTime.parse(iso).toLocal(), isAllDay: allDay == '1', today: today),
      ),
      _ => t.activityDateRemoved,
    },
    ActivityAction.priority => t.activityPriority(labels.priority(Priority.fromCode(int.tryParse(a.detail) ?? 0))),
    ActivityAction.moved => t.activityMoved(switch (s.listById[a.detail]) {
      null => '?',
      final list => labels.listName(list),
    }),
    ActivityAction.repeat => a.detail.isEmpty ? t.activityRepeatRemoved : t.activityRepeat,
    ActivityAction.listCreated => t.activityListCreated,
    ActivityAction.listTitle => t.activityListTitle(a.detail),
    ActivityAction.pinned => t.activityPinned,
    ActivityAction.unpinned => t.activityUnpinned,
    ActivityAction.parent => switch (s.taskById[a.detail]) {
      null => t.activityParentRemoved,
      final p => t.activityParent(p.title.isEmpty ? t.untitled : p.title),
    },
    ActivityAction.tags => a.detail.isEmpty ? t.activityTagsRemoved : t.activityTags(a.detail),
  };
}

class _ActivitiesDialog extends ConsumerWidget {
  const _ActivitiesDialog({this.taskId, this.listId});

  final String? taskId;
  final String? listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final repo = ref.watch(repositoryProvider);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final today = startOfDay(ref.watch(clockProvider).now());
    final dates = DateLabels(t);
    final stream = taskId != null ? repo.watchTaskActivities(taskId!) : repo.watchListActivities(listId!);
    return AlertDialog(
      title: Text(
        taskId != null ? t.activityTaskTitle : t.activityListTitleDialog,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 440,
        height: 420,
        child: StreamBuilder<List<Activity>>(
          stream: stream,
          builder: (context, snap) {
            final items = snap.data ?? const <Activity>[];
            if (items.isEmpty) {
              return Center(
                child: Text(t.activityEmpty, style: TextStyle(color: tt.textTertiary)),
              );
            }
            final rows = <Widget>[];
            DateTime? day;
            for (final a in items) {
              final at = a.createdAt.toLocal();
              if (day != startOfDay(at)) {
                day = startOfDay(at);
                rows.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      dates.dayHeader(day, today),
                      style: TextStyle(fontSize: TtText.small, fontWeight: FontWeight.w700, color: tt.textSecondary),
                    ),
                  ),
                );
              }
              final task = a.taskId == null ? null : s.taskById[a.taskId];
              rows.add(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          DateLabels.time(at),
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activityText(t, a, s, today),
                              style: TextStyle(fontSize: TtText.body, color: tt.text),
                            ),
                            // In the list's activities, which task it was.
                            if (listId != null && task != null)
                              Text(
                                task.title.isEmpty ? t.untitled : task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(children: rows);
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose))],
    );
  }
}
