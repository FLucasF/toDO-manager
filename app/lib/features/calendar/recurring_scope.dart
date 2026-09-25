import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/repository.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';

/// Which occurrences of a repeating task a change applies to (Google Calendar's recurring events).
enum RecurringScope { one, following, all }

/// Whether the occurrence starting on [day] is the task's first (its own dates).
bool isFirstOccurrence(Task task, DateTime day) => startOfDay(task.startLocal ?? day) == startOfDay(day);

/// Google's "Excluir / Editar evento recorrente": Somente esta · Esta e as seguintes · Todas. From the
/// first occurrence "Esta e as seguintes" is the same as "Todas" and is left out. Null when cancelled.
Future<RecurringScope?> askRecurringScope(BuildContext context, {required bool delete, required bool first}) => showDialog<RecurringScope>(
  context: context,
  builder: (_) => _ScopeDialog(delete: delete, first: first),
);

class _ScopeDialog extends StatefulWidget {
  const _ScopeDialog({required this.delete, required this.first});

  final bool delete;
  final bool first;

  @override
  State<_ScopeDialog> createState() => _ScopeDialogState();
}

class _ScopeDialogState extends State<_ScopeDialog> {
  RecurringScope _scope = RecurringScope.one;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.delete ? t.recurringDeleteTitle : t.recurringEditTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
      content: RadioGroup<RecurringScope>(
        groupValue: _scope,
        onChanged: (v) => setState(() => _scope = v ?? _scope),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (scope, label) in [
              (RecurringScope.one, t.recurringOne),
              if (!widget.first) (RecurringScope.following, t.recurringFollowing),
              (RecurringScope.all, t.recurringAll),
            ])
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _scope = scope),
                child: Row(
                  children: [
                    Radio<RecurringScope>(value: scope),
                    Expanded(
                      child: Text(label, style: TextStyle(color: tt.text)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          onPressed: () => Navigator.pop(context, _scope),
          child: Text(t.actionOk),
        ),
      ],
    );
  }
}

/// The scope of a change to [task] at the occurrence starting on [day]: asked when it repeats, else
/// [RecurringScope.all]. Null when cancelled.
Future<RecurringScope?> scopeFor(BuildContext context, Task task, DateTime day, {required bool delete}) async =>
    task.repeatRule == null ? RecurringScope.all : askRecurringScope(context, delete: delete, first: isFirstOccurrence(task, day));

/// Deletes [task] in [scope] (the occurrence starting on [day], it and the ones after, or all), with
/// "Tarefa excluída" and "Desfazer".
Future<void> deleteOccurrence(BuildContext context, Repository repo, Task task, DateTime day, RecurringScope scope) async {
  final t = AppLocalizations.of(context);
  Future<void> apply() => switch (scope) {
    RecurringScope.one => repo.skipOccurrence(task.id, day),
    RecurringScope.following => repo.endSeriesBefore(task.id, day),
    RecurringScope.all => repo.delete(task.id),
  };
  await apply();
  if (context.mounted) showToast(context, t.toastTaskDeleted, undo: () => repo.restoreSeries(task), redo: apply);
}
