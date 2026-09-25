import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart' show AppFlowyEditor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/views.dart';
import '../../features/common/feedback.dart';
import '../../features/search/quick_search.dart';
import '../../features/settings/settings_dialog.dart';
import '../../features/shell/command_palette.dart';
import '../../features/shell/shortcut_help.dart';
import '../../features/common/labels.dart';
import '../../features/tasks/export_print.dart';
import '../../features/tasks/quick_add_modal.dart';
import '../../features/tasks/task_actions.dart';
import '../../features/tasks/timeline_board.dart';
import '../../l10n/app_localizations.dart';
import '../focus_controller.dart';
import '../providers.dart';
import '../routes.dart';
import 'shortcut_bindings.dart';
import 'shortcut_resolver.dart';

/// TickTick's keyboard shortcuts for the whole app. Sits above the router, so it sees
/// every key that no text field or editor used; while typing, only Esc (leave the field) counts.
class GlobalShortcuts extends ConsumerStatefulWidget {
  const GlobalShortcuts({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<GlobalShortcuts> createState() => _GlobalShortcutsState();
}

class _GlobalShortcutsState extends ConsumerState<GlobalShortcuts> {
  final _resolver = ShortcutResolver();
  final _focus = FocusNode(debugLabel: 'GlobalShortcuts');

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_reclaimFocus);
    widget.router.routerDelegate.addListener(_rememberPlace);
  }

  /// Where the search page returns to.
  void _rememberPlace() {
    final location = widget.router.routerDelegate.currentConfiguration.uri.toString();
    if (!Routes.isSearch(location)) Routes.backFromSearch = location;
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_rememberPlace);
    FocusManager.instance.removeListener(_reclaimFocus);
    _focus.dispose();
    super.dispose();
  }

  /// When a field gives up the focus it lands on the window's scope, above this widget, and keys would
  /// no longer reach it; take the focus back. Dialogs and fields sit below, so they are left alone.
  void _reclaimFocus() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary == _focus || !_focus.ancestors.contains(primary)) return;
    scheduleMicrotask(() {
      if (mounted && FocusManager.instance.primaryFocus == primary) _focus.requestFocus();
    });
  }

  static bool _isTyping() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.findAncestorStateOfType<EditableTextState>() != null || context.findAncestorWidgetOfExactType<AppFlowyEditor>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_isTyping()) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
        FocusManager.instance.primaryFocus?.unfocus();
        _focus.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final action = _resolver.resolve(event, control: keyboard.isControlPressed, shift: keyboard.isShiftPressed, alt: keyboard.isAltPressed);
    if (action != null) {
      unawaited(_run(action));
      return KeyEventResult.handled;
    }
    // Tab is a modifier here ("Tab+M"), never focus traversal.
    return event.logicalKey == LogicalKeyboardKey.tab ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  BuildContext? get _navigatorContext => widget.router.routerDelegate.navigatorKey.currentContext;

  ({Scope scope, String? taskId}) get _location {
    final segments = widget.router.routerDelegate.currentConfiguration.uri.pathSegments;
    if (segments.length < 3) return (scope: Routes.scopeOf('q', SmartList.today.route), taskId: null);
    return (scope: Routes.scopeOf(segments[0], segments[1]), taskId: segments.length > 3 ? segments[3] : null);
  }

  Task? get _selected {
    final id = _location.taskId;
    return id == null ? null : ref.read(snapshotProvider).value?.taskById[id];
  }

  void _go(Scope scope, {String? taskId}) => widget.router.go(Routes.of(scope, taskId: taskId));

  Future<void> _run(ShortcutAction action) async {
    final context = _navigatorContext;
    if (context == null || !context.mounted) return;
    final repo = ref.read(repositoryProvider);
    final today = startOfDay(ref.read(clockProvider).now());
    final task = _selected;

    switch (action) {
      case ShortcutAction.addTask:
        await _quickAdd(context);
      case ShortcutAction.search:
        await showQuickSearch(context);
      case ShortcutAction.palette:
        await showCommandPalette(context, onGo: _go, onAddTask: () => _quickAdd(context));
      case ShortcutAction.help:
        await showShortcutHelp(context);
      case ShortcutAction.escape:
        // Esc ends a multi-selection first, then closes the detail; on the search page, goes back.
        if (Routes.isSearch(widget.router.routerDelegate.currentConfiguration.uri.path)) {
          widget.router.go(Routes.backFromSearch);
        } else if (ref.read(taskSelectionProvider).isNotEmpty) {
          ref.read(taskSelectionProvider.notifier).clear();
        } else if (_location.taskId != null) {
          _go(_location.scope);
        }
      case ShortcutAction.goAll:
        _go(const SmartScope(SmartList.all));
      case ShortcutAction.goToday:
        _go(const SmartScope(SmartList.today));
      case ShortcutAction.goTomorrow:
        _go(const SmartScope(SmartList.tomorrow));
      case ShortcutAction.goNext7Days:
        _go(const SmartScope(SmartList.next7Days));
      case ShortcutAction.goInbox:
        _go(const ListScope(inboxListId));
      case ShortcutAction.goCompleted:
        _go(const SmartScope(SmartList.completed));
      case ShortcutAction.goWontDo:
        _go(const SmartScope(SmartList.wontDo));
      case ShortcutAction.goSummary:
        _go(const SmartScope(SmartList.summary));
      case ShortcutAction.goTrash:
        _go(const SmartScope(SmartList.trash));
      case ShortcutAction.goSettings:
        await showSettings(context);
      // Outside text fields (they undo their own typing): the last action with "Desfazer".
      case ShortcutAction.undo:
        if (await ActionHistory.undo() && context.mounted) showToast(context, AppLocalizations.of(context).toastUndone);
      case ShortcutAction.redo:
        if (await ActionHistory.redo() && context.mounted) showToast(context, AppLocalizations.of(context).toastRedone);
      case ShortcutAction.print:
        // Ctrl+P prints the open task, else the visible list.
        final t = AppLocalizations.of(context);
        final open = _selected;
        final view = ref.read(viewProvider(_location.scope));
        final snapshot = ref.read(snapshotProvider).value;
        if (open != null) {
          await printTask(ref, t, open);
        } else if (view != null && snapshot != null) {
          await printView(ref, t, Labels(t).scopeTitle(snapshot, _location.scope), view);
        }
      case ShortcutAction.focusToggle:
        // Ctrl+Shift+P: start, pause or continue the focus from anywhere.
        ref.read(focusProvider.notifier).toggle();
      case ShortcutAction.viewList:
        await setViewMode(ref, _location.scope, ViewMode.list);
      case ShortcutAction.viewKanban:
        await setViewMode(ref, _location.scope, ViewMode.kanban);
      case ShortcutAction.viewTimeline:
        if (supportsTimeline(_location.scope)) await setViewMode(ref, _location.scope, ViewMode.timeline);
      case _ when task == null:
        // The remaining shortcuts act on the task open in the detail.
        break;
      case ShortcutAction.addTaskBelow || ShortcutAction.addSubtask:
        final sub = action == ShortcutAction.addSubtask;
        final id = await repo.createTask(listId: task.listId, sectionId: task.sectionId, parentId: sub ? task.id : task.parentId, atTop: false);
        if (!sub) await _placeAfter(id, task);
        _go(_location.scope, taskId: id);
      case ShortcutAction.toggleSubtasks:
        ref.read(collapsedTasksProvider.notifier).toggle(task.id);
      case ShortcutAction.complete:
        await toggleComplete(context, ref, task);
      case ShortcutAction.pin:
        await repo.pinTask(task.id, pinned: task.pinnedAt == null);
      case ShortcutAction.delete:
        await deleteTask(context, ref, task);
      case ShortcutAction.setDate:
        await pickDueDate(context, ref, task);
      case ShortcutAction.noDate:
        await repo.setSchedule(task.id, dueDate: null);
      case ShortcutAction.today:
        await repo.setDueDate(task.id, today);
      case ShortcutAction.tomorrow:
        await repo.setDueDate(task.id, today.add(const Duration(days: 1)));
      case ShortcutAction.nextWeek:
        await repo.setDueDate(task.id, today.add(const Duration(days: 7)));
      case ShortcutAction.priorityNone:
        await repo.setPriority(task.id, Priority.none);
      case ShortcutAction.priorityLow:
        await repo.setPriority(task.id, Priority.low);
      case ShortcutAction.priorityMedium:
        await repo.setPriority(task.id, Priority.medium);
      case ShortcutAction.priorityHigh:
        await repo.setPriority(task.id, Priority.high);
    }
  }

  /// Global quick add into the visible view's target (its list, tag or date), else the Inbox.
  Future<void> _quickAdd(BuildContext context) {
    final target = ref.read(viewProvider(_location.scope))?.addTarget ?? const AddTarget(listId: inboxListId, hint: AddPlainHint());
    return showQuickAddModal(context, target: target);
  }

  /// "Adicionar tarefa abaixo": the new task goes right after [task] among its siblings.
  Future<void> _placeAfter(String id, Task task) async {
    final s = await ref.read(repositoryProvider).loadSnapshot();
    final siblings =
        s.tasks
            .where(
              (t) => t.id != id && t.listId == task.listId && t.parentId == task.parentId && t.sectionId == task.sectionId && t.deletedAt == null,
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final next = siblings.skipWhile((t) => t.id != task.id).skip(1).firstOrNull;
    if (next != null) await ref.read(repositoryProvider).moveBefore(id, next.id);
  }

  @override
  Widget build(BuildContext context) {
    // Settings → Atalhos.
    _resolver.bindings = ShortcutBindings.merged(ref.watch(preferencesProvider).value?.customShortcuts ?? const {});
    return Focus(focusNode: _focus, autofocus: true, onKeyEvent: _onKey, child: widget.child);
  }
}
