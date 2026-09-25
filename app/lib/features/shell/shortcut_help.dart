import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shortcuts/shortcut_bindings.dart';
import '../../app/shortcuts/shortcut_resolver.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../common/labels.dart';

/// "Lista de atalhos" ("?"): the shortcuts the app answers to, by group.
Future<void> showShortcutHelp(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _ShortcutHelp());

class _ShortcutHelp extends StatelessWidget {
  const _ShortcutHelp();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(t.shortcutsTitle, style: const TextStyle(fontSize: 15)),
      content: const SizedBox(width: 440, child: SingleChildScrollView(child: ShortcutList())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionOk))],
    );
  }
}

/// Name of an action in the list of shortcuts.
String shortcutActionLabel(AppLocalizations t, ShortcutAction a) {
  final labels = Labels(t);
  String go(String name) => t.shortcutGoTo(name);
  return switch (a) {
    ShortcutAction.palette => t.shortcutPalette,
    ShortcutAction.print => t.menuPrint,
    ShortcutAction.focusToggle => t.shortcutFocusToggle,
    ShortcutAction.help => t.shortcutList,
    ShortcutAction.search => t.shortcutSearch,
    ShortcutAction.addTask => t.shortcutAddTask,
    ShortcutAction.toggleSubtasks => t.shortcutToggleSubtasks,
    ShortcutAction.complete => t.shortcutComplete,
    ShortcutAction.pin => t.shortcutPin,
    ShortcutAction.delete => t.shortcutDelete,
    ShortcutAction.setDate => t.shortcutSetDate,
    ShortcutAction.noDate => t.shortcutNoDate,
    ShortcutAction.today => '${t.menuDate}: ${t.dateToday}',
    ShortcutAction.tomorrow => '${t.menuDate}: ${t.dateTomorrow}',
    ShortcutAction.nextWeek => '${t.menuDate}: ${t.dateNextWeek}',
    ShortcutAction.priorityNone => '${t.menuPriority}: ${t.priorityNone}',
    ShortcutAction.priorityLow => '${t.menuPriority}: ${t.priorityLow}',
    ShortcutAction.priorityMedium => '${t.menuPriority}: ${t.priorityMedium}',
    ShortcutAction.priorityHigh => '${t.menuPriority}: ${t.priorityHigh}',
    ShortcutAction.goAll => go(labels.smartList(SmartList.all)),
    ShortcutAction.goToday => go(labels.smartList(SmartList.today)),
    ShortcutAction.goTomorrow => go(labels.smartList(SmartList.tomorrow)),
    ShortcutAction.goNext7Days => go(labels.smartList(SmartList.next7Days)),
    ShortcutAction.goInbox => go(t.inbox),
    ShortcutAction.goCompleted => go(labels.smartList(SmartList.completed)),
    ShortcutAction.goWontDo => go(labels.smartList(SmartList.wontDo)),
    ShortcutAction.goSummary => go(labels.smartList(SmartList.summary)),
    ShortcutAction.goTrash => go(labels.smartList(SmartList.trash)),
    ShortcutAction.goSettings => t.shortcutSettings,
    ShortcutAction.viewList => t.shortcutViewAs(t.viewList),
    ShortcutAction.viewKanban => t.shortcutViewAs(t.viewKanban),
    ShortcutAction.viewTimeline => t.shortcutViewAs(t.viewTimeline),
    ShortcutAction.undo => t.shortcutUndo,
    ShortcutAction.redo => t.shortcutRedo,
    _ => a.name,
  };
}

/// The shortcuts by group, with the keys set in Settings → Atalhos. [editable]: a click on an action
/// records new keys (Settings → Atalhos).
class ShortcutList extends ConsumerWidget {
  const ShortcutList({super.key, this.editable = false});

  final bool editable;

  static const _groups = <List<ShortcutAction>>[
    [ShortcutAction.undo, ShortcutAction.redo, ShortcutAction.print, ShortcutAction.focusToggle, ShortcutAction.palette, ShortcutAction.help],
    [ShortcutAction.addTask, ShortcutAction.toggleSubtasks, ShortcutAction.viewList, ShortcutAction.viewKanban, ShortcutAction.viewTimeline],
    [
      ShortcutAction.complete,
      ShortcutAction.pin,
      ShortcutAction.delete,
      ShortcutAction.setDate,
      ShortcutAction.noDate,
      ShortcutAction.today,
      ShortcutAction.tomorrow,
      ShortcutAction.nextWeek,
      ShortcutAction.priorityNone,
      ShortcutAction.priorityLow,
      ShortcutAction.priorityMedium,
      ShortcutAction.priorityHigh,
    ],
    [
      ShortcutAction.search,
      ShortcutAction.goSettings,
      ShortcutAction.goAll,
      ShortcutAction.goToday,
      ShortcutAction.goTomorrow,
      ShortcutAction.goNext7Days,
      ShortcutAction.goInbox,
      ShortcutAction.goCompleted,
      ShortcutAction.goWontDo,
      ShortcutAction.goSummary,
      ShortcutAction.goTrash,
    ],
  ];

  Future<void> _record(BuildContext context, WidgetRef ref, ShortcutAction action) async {
    final t = AppLocalizations.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _RecordDialog(action: action),
    );
    if (picked == null) return;
    final prefs = ref.read(preferencesProvider).value ?? Preferences.defaults;
    final custom = {...prefs.customShortcuts};
    final current = ShortcutBindings.merged(custom);
    if (picked.isEmpty) {
      custom[action.name] = const [];
    } else {
      final key = ShortcutBindings.normalize(picked)!;
      // The keys leave the action that had them.
      for (final e in current.entries) {
        if (e.key != action && e.value.any((b) => ShortcutBindings.normalize(b) == key)) {
          custom[e.key.name] = [
            for (final b in e.value)
              if (ShortcutBindings.normalize(b) != key) b,
          ];
          if (context.mounted) showToast(context, t.shortcutConflict(shortcutActionLabel(t, e.key)));
        }
      }
      custom[action.name] = [picked];
    }
    await ref.read(preferencesRepositoryProvider).setCustomShortcuts(custom);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final prefs = ref.watch(preferencesProvider).value ?? Preferences.defaults;
    final bindings = ShortcutBindings.merged(prefs.customShortcuts);
    final titles = [t.shortcutsGeneral, t.shortcutsTask, t.shortcutsEditTask, t.shortcutsNavigation];

    Widget key(String label) => Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tt.fieldFill,
        border: Border.all(color: tt.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: tt.textSecondary)),
    );
    Widget row(String label, List<String> keys, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: tt.text, fontSize: TtText.body),
              ),
            ),
            if (keys.isEmpty) Text(t.shortcutNone, style: TextStyle(fontSize: 11, color: tt.textFaint)) else for (final k in keys) key(k),
          ],
        ),
      ),
    );
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: tt.textTertiary, fontSize: TtText.small),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (editable)
          Row(
            children: [
              Expanded(
                child: Text(
                  t.shortcutEditHint,
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
              ),
              TextButton(
                onPressed: prefs.customShortcuts.isEmpty
                    ? null
                    : () => unawaited(ref.read(preferencesRepositoryProvider).setCustomShortcuts(const {})),
                child: Text(t.shortcutRestoreAll),
              ),
            ],
          ),
        for (final (i, actions) in _groups.indexed) ...[
          title(titles[i]),
          if (i == 0) row(t.shortcutCancel, ['Esc']),
          if (i == 1) ...[
            row(t.shortcutAddTaskBelow, ['Enter']),
            row(t.shortcutAddSubtask, ['Shift+Enter']),
          ],
          for (final a in actions)
            row(shortcutActionLabel(t, a), [
              for (final b in bindings[a] ?? const <String>[]) ShortcutBindings.display(b),
            ], onTap: editable ? () => unawaited(_record(context, ref, a)) : null),
        ],
        title(t.navCalendar),
        row(t.shortcutCalendarModes, ['D', 'W', 'M', 'Y', 'A']),
        row(t.shortcutCalendarToday, ['T']),
      ],
    );
  }
}

/// "Pressione as teclas": records one combo, a Tab combo, one key or (with "Sequência") two keys.
class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.action});

  final ShortcutAction action;

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _focus = FocusNode();
  bool _sequence = false;
  bool _tab = false;
  String? _first;
  String? _recorded;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static bool _isModifier(LogicalKeyboardKey k) => {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  }.contains(k);

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) {
      if (event is KeyDownEvent) _tab = true;
      if (event is KeyUpEvent) _tab = false;
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent || _isModifier(key)) return KeyEventResult.handled;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    final name = ShortcutResolver.keyName(key);
    final letter = RegExp(r'^[a-z0-9]$').hasMatch(name);
    setState(() {
      if (_tab && letter) {
        _recorded = 'Tab+${name.toUpperCase()}';
      } else if (keyboard.isControlPressed || keyboard.isAltPressed) {
        _recorded = [if (keyboard.isControlPressed) 'Ctrl', if (keyboard.isShiftPressed) 'Shift', if (keyboard.isAltPressed) 'Alt', name].join('+');
      } else if (_sequence && letter) {
        if (_first == null) {
          _first = name;
          _recorded = null;
        } else {
          _recorded = '$_first $name';
          _first = null;
        }
      } else {
        final character = event.character;
        _recorded = character != null && character.length == 1 && !letter ? character : (letter ? name : null);
      }
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final shown = _recorded ?? (_first == null ? null : '${_first!.toUpperCase()}→…');
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: Text(t.shortcutRecordTitle(shortcutActionLabel(t, widget.action)), style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.shortcutRecordHint,
                style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tt.fieldFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tt.primary),
                ),
                child: Text(
                  shown == null ? '…' : (shown.contains('…') ? shown : ShortcutBindings.display(shown)),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tt.text),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.shortcutSequence),
                value: _sequence,
                onChanged: (v) => setState(() {
                  _sequence = v ?? false;
                  _first = null;
                  _recorded = null;
                  _focus.requestFocus();
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ''), child: Text(t.shortcutRemove)),
          const SizedBox(width: 24),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
          FilledButton(
            onPressed: _recorded == null || ShortcutBindings.normalize(_recorded!) == null ? null : () => Navigator.pop(context, _recorded),
            child: Text(t.actionSave),
          ),
        ],
      ),
    );
  }
}
