import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/preferences_repository.dart';
import '../../domain/enums.dart';
import '../../domain/quick_add.dart';
import '../../domain/recurrence.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_defaults.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import 'quick_add_suggestions.dart';
import '../../data/url_title.dart';

/// Creates a task from quick-add text in [target]. The text's own `!prioridade`, `#tag`,
/// `~lista` and date win; otherwise [schedule], [priority] and [listId] (the modal's icons) apply.
/// Returns the new task id, or null for empty text.
Future<String?> createFromQuickAdd(
  WidgetRef ref,
  AppLocalizations t, {
  required String text,
  required AddTarget target,
  DateSelection? schedule,
  Priority? priority,
  String? listId,
  String? sectionId,
  Set<String> tagIds = const {},
  TaskKind? kind,
}) async {
  final title = text.trim();
  if (title.isEmpty) return null;
  final repo = ref.read(repositoryProvider);
  final snapshot = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final lists = snapshot.activeLists;
  final labels = Labels(t);
  final defaults = (ref.read(preferencesProvider).value ?? Preferences.defaults).taskDefaults;
  final now = ref.read(clockProvider).now();
  target = withDefaultList(target, defaults, snapshot);
  final parsed = parseQuickAdd(
    title,
    now: now,
    listNames: [for (final l in lists) labels.listName(l)],
    recognizeDates: defaults.recognizeDates,
    removeDateText: defaults.removeDateText,
    removeTagText: defaults.removeTagText,
  );
  final chosenList = parsed.listName == null ? (listId ?? target.listId) : lists.firstWhere((l) => labels.listName(l) == parsed.listName).id;
  // "Tag padrão", while that tag still exists.
  final defaultTag = defaults.tagId != null && snapshot.tagById.containsKey(defaults.tagId) ? defaults.tagId : null;
  final tags = <String>{
    if (target.tagId != null) target.tagId!,
    ?defaultTag,
    ...tagIds,
    for (final name in parsed.tagNames) await repo.createTag(name),
  };
  // A date typed in the text wins over the one picked with the calendar icon.
  final picked = parsed.dueDate == null ? schedule : null;
  final due = parsed.dueDate ?? picked?.dueDate ?? target.dueDate ?? defaultDueDate(defaults.date, startOfDay(now));
  final allDay = picked?.isAllDay ?? (parsed.dueDate == null || parsed.isAllDay);
  // "Duração padrão": a task with a time and no end of its own gets the default length.
  final length = defaults.durationMinutes;
  final withDuration = due != null && !allDay && picked?.startDate == null && length != null;
  // Default reminders: "Lembrete padrão" of timed and of all-day tasks.
  final reminder = due == null ? null : (allDay ? defaults.allDayReminder : defaults.timedReminder);
  final id = await repo.createTask(
    listId: chosenList,
    // A Kanban column's section, unless the text sends the task to another list.
    sectionId: chosenList == (listId ?? target.listId) ? sectionId : null,
    title: parsed.title,
    dueDate: withDuration ? due.add(Duration(minutes: length)) : due,
    startDate: withDuration ? due : picked?.startDate,
    isAllDay: allDay,
    priority: parsed.priority ?? priority ?? defaults.priority,
    tagIds: tags,
    repeatRule: picked?.repeatRule,
    repeatFrom: picked?.repeatFrom ?? RepeatFrom.dueDate,
    reminders: picked?.reminders ?? [?reminder],
    atTop: defaults.addAtTop,
    kind: kind ?? TaskKind.text,
  );
  // "Análise de URL": a bare link gets the page's title (in the background; the link goes to the content).
  final link = defaults.parseUrls ? bareUrl(parsed.title) : null;
  if (link != null) {
    unawaited(
      fetchPageTitle(link).then((title) async {
        if (title != null) await repo.titleFromLink(id, title: title, url: link);
      }),
    );
  }
  return id;
}

/// [target] sent to the "Lista padrão" when it is outside a list and that list still exists.
AddTarget withDefaultList(AddTarget target, TaskDefaults defaults, Snapshot s) {
  final list = s.listById[defaults.listId];
  if (!target.usesDefaultList || list == null || list.deletedAt != null || list.archivedAt != null || list.id == target.listId) return target;
  return target.withList(list.id);
}

/// Text field with the quick-add token popups: `!`, `#`, `*`, `~`/`^` open suggestions
/// under the field; arrows + Enter/Tab or a tap insert the choice, Esc closes them.
class QuickAddTextField extends ConsumerStatefulWidget {
  const QuickAddTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.hint,
    this.style,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final String? hint;
  final TextStyle? style;
  final bool autofocus;

  @override
  ConsumerState<QuickAddTextField> createState() => _QuickAddTextFieldState();
}

class _QuickAddTextFieldState extends ConsumerState<QuickAddTextField> {
  final _popup = OverlayPortalController();
  final _link = LayerLink();
  ActiveToken? _token;
  List<QuickAddSuggestion> _suggestions = const [];
  int _highlighted = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.focusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    widget.focusNode.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final selection = widget.controller.selection;
    final token = widget.focusNode.hasFocus && selection.isCollapsed ? activeToken(widget.controller.text, selection.baseOffset) : null;
    final suggestions = token == null
        ? const <QuickAddSuggestion>[]
        : quickAddSuggestions(
            token,
            ref.read(snapshotProvider).value ?? Snapshot.empty(),
            AppLocalizations.of(context),
            context.tt,
            ref.read(clockProvider).now(),
          );
    setState(() {
      _token = token;
      _suggestions = suggestions;
      _highlighted = 0;
    });
    suggestions.isEmpty ? _popup.hide() : _popup.show();
  }

  void _apply(QuickAddSuggestion suggestion) {
    final token = _token;
    if (token == null) return;
    final result = replaceToken(widget.controller.text, token, suggestion.insert);
    widget.controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursor),
    );
    widget.focusNode.requestFocus();
  }

  /// Arrows move through the popup, Enter or Tab choose, Esc closes it. The keys bubble up from the
  /// field to the [Focus] around it before the app's text-editing shortcuts see them.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_suggestions.isEmpty || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      setState(() => _highlighted = (_highlighted + step) % _suggestions.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || key == LogicalKeyboardKey.tab) {
      _apply(_suggestions[_highlighted]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() => _suggestions = const []);
      _popup.hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return OverlayPortal(
      controller: _popup,
      overlayChildBuilder: (context) => CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, 8),
        child: Align(
          alignment: Alignment.topLeft,
          // Inside the field's tap region, so tapping a suggestion keeps the keyboard up on phones.
          child: TextFieldTapRegion(
            child: SizedBox(
              width: 280,
              child: QuickAddSuggestionList(suggestions: _suggestions, highlighted: _highlighted, onSelect: _apply),
            ),
          ),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            style: widget.style ?? TextStyle(fontSize: TtText.body, color: tt.text),
            decoration: InputDecoration(hintText: widget.hint, border: InputBorder.none, isCollapsed: true),
            onSubmitted: widget.onSubmitted,
          ),
        ),
      ),
    );
  }
}
