import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import 'task_actions.dart';

/// A phone's bar while tasks are selected: ✕, "Você escolheu N itens" and Editar, which opens the
/// batch panel on the whole screen.
class PhoneSelectionBar extends ConsumerWidget {
  const PhoneSelectionBar({super.key, required this.scope});

  final Scope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final count = ref.watch(taskSelectionProvider).length;
    return Material(
      color: tt.screen,
      shape: Border(top: BorderSide(color: tt.divider)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
          child: Row(
            children: [
              IconButton(
                tooltip: t.actionCancel,
                icon: Icon(Icons.close, color: tt.textSecondary),
                onPressed: ref.read(taskSelectionProvider.notifier).clear,
              ),
              Expanded(
                child: Text(
                  t.batchSelected(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                ),
              ),
              FilledButton(
                onPressed: () => unawaited(
                  showDialog<void>(
                    context: context,
                    builder: (_) => Dialog.fullscreen(
                      child: SafeArea(child: _PhoneBatch(scope: scope)),
                    ),
                  ),
                ),
                child: Text(t.actionEdit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The batch panel on a phone's screen; it closes when the selection ends (Cancelar or an action).
class _PhoneBatch extends ConsumerStatefulWidget {
  const _PhoneBatch({required this.scope});

  final Scope scope;

  @override
  ConsumerState<_PhoneBatch> createState() => _PhoneBatchState();
}

class _PhoneBatchState extends ConsumerState<_PhoneBatch> {
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(taskSelectionProvider, (_, ids) {
      if (ids.isEmpty && !_closed) {
        _closed = true;
        Navigator.pop(context);
      }
    });
    return BatchPane(scope: widget.scope);
  }
}

/// Right panel while several tasks are selected: "Você escolheu N itens" + Cancelar;
/// batch fields Dia do vencimento, Atrasar, Prioridade, Lista, Etiquetas; actions Concluído, Fixar,
/// Não farei, Vincular Tarefa Pai, Mesclar, Duplicar, Converter para nota, Copiar Texto, Deletar.
class BatchPane extends ConsumerWidget {
  const BatchPane({super.key, required this.scope});

  final Scope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final ids = ref.watch(taskSelectionProvider);
    final tasks = [for (final id in ids) ?s.taskById[id]];
    final repo = ref.read(repositoryProvider);
    final selection = ref.read(taskSelectionProvider.notifier);

    Future<void> each(Future<void> Function(Task task) action) async {
      for (final task in tasks) {
        await action(task);
      }
    }

    // Converting needs tasks without subtasks.
    final canConvert = tasks.any((t) => t.kind != TaskKind.note) && tasks.every((t) => s.childrenOf(t.id).isEmpty);
    final sameList = tasks.map((t) => t.listId).toSet().length == 1;

    Widget field(IconData icon, String label, VoidCallback onTap) => ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: tt.textSecondary),
      title: Text(
        label,
        style: TextStyle(color: tt.text, fontSize: TtText.body),
      ),
      trailing: Icon(Icons.chevron_right, size: 16, color: tt.textTertiary),
      onTap: onTap,
    );

    Widget action(IconData icon, String label, Future<void> Function()? run, {Color? color, bool clears = true}) => ListTile(
      dense: true,
      enabled: run != null,
      leading: Icon(icon, size: 18, color: run == null ? tt.textFaint : (color ?? tt.textSecondary)),
      title: Text(
        label,
        style: TextStyle(color: run == null ? tt.textFaint : (color ?? tt.text), fontSize: TtText.body),
      ),
      onTap: run == null
          ? null
          : () => unawaited(() async {
              await run();
              if (clears) selection.clear();
            }()),
    );

    Future<void> menu<T>(BuildContext context, Map<T, String> options, Future<void> Function(T value) apply) async {
      final box = context.findRenderObject()! as RenderBox;
      final origin = box.localToGlobal(Offset(box.size.width / 2, box.size.height));
      final picked = await showMenu<T>(
        context: context,
        position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
        items: [for (final o in options.entries) PopupMenuItem(value: o.key, height: 36, child: Text(o.value))],
      );
      if (picked != null) await apply(picked);
    }

    return Material(
      color: tt.screen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.batchSelected(tasks.length),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: tt.text),
                ),
              ),
              TextButton(onPressed: selection.clear, child: Text(t.actionCancel)),
            ],
          ),
          const SizedBox(height: 8),
          field(Icons.calendar_today_outlined, t.batchDueDate, () async {
            final picked = await showTtDatePicker(context, initial: const DateSelection(), now: ref.read(clockProvider).now());
            if (picked == null) return;
            await each(
              (task) => repo.setSchedule(
                task.id,
                dueDate: picked.dueDate,
                startDate: picked.startDate,
                isAllDay: picked.isAllDay,
                reminders: picked.reminders,
                repeatRule: picked.repeatRule,
                repeatFrom: picked.repeatFrom,
              ),
            );
          }),
          Builder(
            builder: (context) => field(Icons.update, t.batchPostpone, () async {
              await menu<int>(context, {1: t.postpone1Day, 7: t.postpone1Week, 0: t.postponeCustom}, (days) async {
                var n = days;
                if (n == 0) {
                  final text = await promptText(context, title: t.postponeDaysPrompt, initial: '3');
                  n = int.tryParse(text?.trim() ?? '') ?? 0;
                }
                if (n > 0) await each((task) => repo.postpone(task.id, n));
              });
            }),
          ),
          Builder(
            builder: (context) => field(Icons.flag_outlined, t.batchPriority, () async {
              await menu<Priority>(context, {
                for (final p in Priority.values.reversed) p: labels.priority(p),
              }, (p) => each((task) => repo.setPriority(task.id, p)));
            }),
          ),
          field(Icons.drive_file_move_outline, t.batchList, () async {
            final picked = await pickListTarget(context, ref);
            if (picked != null) await each((task) => repo.move(task.id, picked.$1, sectionId: picked.$2));
          }),
          field(Icons.sell_outlined, t.batchTags, () async {
            final picked = await pickTags(context, ref);
            if (picked == null || picked.isEmpty) return;
            // Adds the tags to each task, keeping the ones it has.
            await each((task) => repo.setTaskTags(task.id, {for (final tag in s.tagsOf(task.id)) tag.id, ...picked}));
          }),
          const Divider(height: 24),
          action(
            Icons.check_box_outlined,
            t.batchComplete,
            () => each((task) async {
              if (task.status == TaskStatus.open) await repo.complete(task.id);
            }),
          ),
          action(Icons.push_pin_outlined, t.batchPin, () {
            final pin = tasks.any((task) => task.pinnedAt == null);
            return each((task) => repo.pinTask(task.id, pinned: pin));
          }, clears: false),
          action(
            Icons.block,
            t.batchWontDo,
            () => each((task) async {
              if (task.status == TaskStatus.open) await repo.markWontDo(task.id);
            }),
          ),
          action(
            Icons.account_tree_outlined,
            t.batchLinkParent,
            !sameList
                ? null
                : () async {
                    final parent = await pickParentTask(context, ref, listId: tasks.first.listId, exclude: ids);
                    if (parent == null || !context.mounted) return;
                    await guarded(context, () => each((task) => repo.makeSubtask(task.id, parent)));
                  },
          ),
          action(Icons.merge, t.batchMerge, () async {
            if (!await confirm(context, message: t.mergeConfirm(tasks.length))) return;
            final merged = await repo.merge([for (final task in tasks) task.id], t.mergedTitle);
            if (context.mounted) context.go(Routes.of(scope, taskId: merged));
          }),
          action(Icons.copy_all_outlined, t.batchDuplicate, () => each((task) async => repo.duplicate(task.id))),
          action(Icons.description_outlined, t.batchConvertNote, !canConvert ? null : () => each((task) => repo.convert(task.id, TaskKind.note))),
          action(Icons.content_copy, t.batchCopyText, () async {
            await Clipboard.setData(ClipboardData(text: [for (final task in tasks) task.title].join('\n')));
            if (context.mounted) showToast(context, t.toastCopied);
          }, clears: false),
          action(Icons.delete_outline, t.batchDelete, () async {
            final deleted = [for (final task in tasks) task.id];
            for (final id in deleted) {
              await repo.delete(id);
            }
            if (context.mounted) {
              showToast(
                context,
                t.toastTaskDeleted,
                undo: () async {
                  for (final id in deleted) {
                    await repo.restore(id);
                  }
                },
                redo: () async {
                  for (final id in deleted) {
                    await repo.delete(id);
                  }
                },
              );
            }
          }, color: tt.overdue),
        ],
      ),
    );
  }
}
