import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../data/preferences_repository.dart';
import '../../domain/custom_repeat.dart' show byDayCodes, weekdayInMonth;
import '../../domain/enums.dart';
import '../../domain/reminders.dart';
import '../../domain/snapshot.dart';
import '../../domain/task_dates.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/feedback.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import 'color_label_menu.dart';
import 'custom_recurrence_dialog.dart';
import 'recurring_scope.dart';

/// What the create card hands to "Mais opções", or an existing task ("Editar" in the details popup).
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.kind,
    required this.listId,
    required this.schedule,
    this.taskId,
    this.priority = Priority.none,
    this.color,
    this.occurrence,
  });

  /// [task] as it is, with its [reminders]; from an [occurrence] of a repeating task (its start), with
  /// that occurrence's dates.
  factory TaskDraft.of(Task task, Iterable<String> reminders, {DateTime? occurrence}) {
    final shift = occurrence == null || task.startLocal == null ? Duration.zero : occurrence.difference(task.startLocal!);
    final due = task.endLocal?.add(shift);
    final start = task.startLocal?.add(shift);
    return TaskDraft(
      taskId: task.id,
      occurrence: task.repeatRule == null ? null : (occurrence ?? task.startLocal),
      title: task.title,
      description: task.content,
      kind: task.kind,
      listId: task.listId,
      priority: task.priority,
      color: task.color,
      schedule: DateSelection(
        dueDate: due,
        startDate: start != null && due != null && start.isBefore(due) ? start : null,
        isAllDay: task.isAllDay,
        reminders: reminders.toSet(),
        repeatRule: task.repeatRule,
      ),
    );
  }

  /// The task being edited; null for a new one.
  final String? taskId;
  final String title;
  final String description;
  final TaskKind kind;
  final String listId;
  final DateSelection schedule;
  final Priority priority;
  final String? color;

  /// The occurrence being edited (its start), for a repeating task.
  final DateTime? occurrence;
}

/// "Mais opções": Google Calendar's full event page for a new task
/// or, with [TaskDraft.taskId], an existing one. Returns the task's id, or null when closed without saving.
Future<String?> showTaskEditPage(BuildContext context, TaskDraft draft) => showDialog<String>(
  context: context,
  builder: (_) => Dialog.fullscreen(child: _EditPage(draft: draft)),
);

class _EditPage extends ConsumerStatefulWidget {
  const _EditPage({required this.draft});

  final TaskDraft draft;

  @override
  ConsumerState<_EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<_EditPage> {
  late final _title = TextEditingController(text: widget.draft.title);
  late final _description = TextEditingController(text: widget.draft.description);
  late TaskKind _kind = widget.draft.kind;
  late String _listId = widget.draft.listId;
  late Priority _priority = widget.draft.priority;

  /// Its own color (Google's event color); null = the list's.
  late String? _color = widget.draft.color;

  late bool _allDay;
  late DateTime _start;
  late DateTime _end;
  String? _rule;
  late Set<String> _reminders;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.draft.schedule;
    final now = ref.read(clockProvider).now();
    final due = s.dueDate ?? DateTime(now.year, now.month, now.day, now.hour + 1);
    _allDay = s.dueDate != null && s.isAllDay;
    _start = s.startDate ?? due;
    // A new timed task gets Google's hour; an existing one keeps its length (none at a point in time).
    _end = s.startDate == null && !_allDay && widget.draft.taskId == null ? due.add(const Duration(hours: 1)) : due;
    _rule = s.repeatRule;
    _reminders = {...s.reminders};
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    // TickTick's model: the due date is the end; a start only when there is a duration.
    final sameDay = startOfDay(_start) == startOfDay(_end);
    final due = _allDay ? startOfDay(_end) : _end;
    final start = _allDay ? (sameDay ? null : startOfDay(_start)) : (_end.isAfter(_start) ? _start : null);
    if (widget.draft.taskId case final id?) {
      final newDue = start == null && !_allDay ? _start : due;
      final task = ref.read(snapshotProvider).value?.taskById[id];
      final occurrence = widget.draft.occurrence;
      // A repeating task: "Somente esta", "Esta e as seguintes" or "Todas", as Google's.
      final scope = task == null || occurrence == null ? RecurringScope.all : await scopeFor(context, task, occurrence, delete: false);
      if (scope == null || task == null && occurrence != null) {
        _saving = false;
        return;
      }
      final repo = ref.read(repositoryProvider);
      switch (scope) {
        case RecurringScope.all:
          // From a later occurrence, the change moves the series by as much.
          final back = occurrence == null || task?.startLocal == null ? Duration.zero : task!.startLocal!.difference(occurrence);
          await _update(id, due: newDue.add(back), start: start?.add(back));
        case RecurringScope.one:
          final copy = await repo.duplicate(id);
          await _applyAll(copy, due: newDue, start: start, rule: null);
          await repo.skipOccurrence(id, occurrence!);
        case RecurringScope.following:
          final copy = await repo.duplicate(id);
          await _applyAll(copy, due: newDue, start: start, rule: _rule);
          await repo.endSeriesBefore(id, occurrence!);
      }
      if (mounted) Navigator.pop(context, id);
      return;
    }
    final id = await ref
        .read(repositoryProvider)
        .createTask(
          listId: _listId,
          title: _title.text.trim(),
          content: _description.text.trim(),
          dueDate: start == null && !_allDay ? _start : due,
          startDate: start,
          isAllDay: _allDay,
          kind: _kind,
          priority: _priority,
          reminders: _reminders,
          repeatRule: _rule,
          color: _color,
        );
    if (mounted) Navigator.pop(context, id);
  }

  /// Saves an existing task: only what changed, so its "Atividades" stay clean.
  Future<void> _update(String id, {required DateTime due, required DateTime? start}) async {
    final repo = ref.read(repositoryProvider);
    final d = widget.draft;
    final title = _title.text.trim();
    final content = _description.text.trim();
    if (title != d.title) await repo.setTitle(id, title);
    if (content != d.description.trim()) await repo.setContent(id, content);
    if (_listId != d.listId) await repo.move(id, _listId);
    if (_kind != d.kind && mounted) await guarded(context, () => repo.convert(id, _kind));
    await repo.setSchedule(id, dueDate: due, startDate: start, isAllDay: _allDay, reminders: _reminders, repeatRule: _rule);
    if (_priority != d.priority) await repo.setPriority(id, _priority);
    if (_color != d.color) await repo.setTaskColor(id, _color);
  }

  /// Everything on the page, written to [id] (a copy of the task for "Somente esta" and "Esta e as
  /// seguintes").
  Future<void> _applyAll(String id, {required DateTime due, required DateTime? start, required String? rule}) async {
    final repo = ref.read(repositoryProvider);
    final d = widget.draft;
    await repo.setTitle(id, _title.text.trim());
    await repo.setContent(id, _description.text.trim());
    if (_listId != d.listId) await repo.move(id, _listId);
    if (_kind != d.kind && mounted) await guarded(context, () => repo.convert(id, _kind));
    await repo.setSchedule(id, dueDate: due, startDate: start, isAllDay: _allDay, reminders: _reminders, repeatRule: rule);
    await repo.setPriority(id, _priority);
    await repo.setTaskColor(id, _color);
  }

  Future<DateTime?> _pickDay(DateTime initial) =>
      showDatePicker(context: context, initialDate: initial, firstDate: DateTime(initial.year - 20), lastDate: DateTime(initial.year + 20));

  DateTime _withDay(DateTime time, DateTime day) => DateTime(day.year, day.month, day.day, time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final lists = s.activeLists;
    final list = s.listById[_listId];
    final narrow = MediaQuery.sizeOf(context).width < TtSizes.narrowBreakpoint;

    String dayLabel(DateTime d) => '${d.day} de ${dates.monthShort(d)}. de ${d.year}';

    Widget pill(String text, VoidCallback onTap, {bool menu = false}) => InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, menu ? 4 : 12, 8),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: TtText.body, color: tt.text),
            ),
            if (menu) Icon(Icons.arrow_drop_down, size: 20, color: tt.textSecondary),
          ],
        ),
      ),
    );

    // Times every 15 minutes, as Google's list.
    Widget timePill(DateTime value, ValueChanged<DateTime> onPicked) => PopupMenuButton<int>(
      tooltip: '',
      constraints: const BoxConstraints(maxHeight: 320),
      initialValue: value.hour * 60 + value.minute ~/ 15 * 15,
      onSelected: (m) => onPicked(DateTime(value.year, value.month, value.day, m ~/ 60, m % 60)),
      itemBuilder: (_) => [
        for (var m = 0; m < 24 * 60; m += 15)
          PopupMenuItem(value: m, height: 32, child: Text(DateLabels.time(DateTime(2000, 1, 1, m ~/ 60, m % 60)))),
      ],
      child: IgnorePointer(child: pill(DateLabels.time(value), () {})),
    );

    // Google's repetition choices for the start day, then "Personalizar…".
    final day = _start;
    final code = byDayCodes[day.weekday - 1];
    final place = weekdayInMonth(day);
    final repeats = <String?, String>{
      null: t.calendarNoRepeat,
      'FREQ=DAILY;INTERVAL=1': t.repeatDaily,
      'FREQ=WEEKLY;INTERVAL=1;BYDAY=$code': t.recurrenceWeeklyOn(dates.weekday(day).toLowerCase()),
      if (place.nth <= 4) 'FREQ=MONTHLY;INTERVAL=1;BYDAY=${place.nth}$code': t.repeatMonthlyOn(weekdayOfMonth(t, dates, place.nth, day.weekday)),
      if (place.last) 'FREQ=MONTHLY;INTERVAL=1;BYDAY=-1$code': t.repeatMonthlyOn(weekdayOfMonth(t, dates, -1, day.weekday)),
      'FREQ=YEARLY;INTERVAL=1;BYMONTH=${day.month};BYMONTHDAY=${day.day}': t.recurrenceYearlyOn(
        '${day.day} de ${dates.monthLong(day).toLowerCase()}',
      ),
      'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR': t.repeatWeekdays,
    };
    final ruleLabel = repeats[_rule] ?? (_rule == null ? t.calendarNoRepeat : recurrenceSummary(t, dates, _rule!, day));

    Widget section(IconData icon, Widget child, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(icon, size: 20, color: color ?? tt.textSecondary),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );

    final presets = _allDay ? ReminderPresets.allDay : ReminderPresets.timed;

    return Material(
      color: tt.screen,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: EdgeInsets.fromLTRB(narrow ? 8 : 16, 12, narrow ? 8 : 16, 32),
              children: [
                // ✕ · title · Salvar
                Row(
                  children: [
                    IconButton(
                      tooltip: t.actionClose,
                      icon: Icon(Icons.close, color: tt.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _title,
                        autofocus: _title.text.isEmpty,
                        style: TextStyle(fontSize: 22, color: tt.text),
                        decoration: InputDecoration(
                          hintText: t.calendarAddTitle,
                          hintStyle: TextStyle(fontSize: 22, color: tt.textTertiary),
                          isDense: true,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tt.divider)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tt.primary, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                      onPressed: () => unawaited(_save()),
                      child: Text(t.actionSave),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
                // Start date · start time – end time · end date; Dia inteiro · repetition.
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      pill(dayLabel(_start), () async {
                        final picked = await _pickDay(_start);
                        if (picked == null) return;
                        final length = _end.difference(_start);
                        setState(() {
                          _start = _withDay(_start, picked);
                          _end = _start.add(length);
                        });
                      }),
                      if (!_allDay) ...[
                        timePill(_start, (v) {
                          final length = _end.difference(_start);
                          setState(() {
                            _start = v;
                            _end = v.add(length);
                          });
                        }),
                        Text('–', style: TextStyle(color: tt.textSecondary)),
                        timePill(_end, (v) => setState(() => _end = v.isBefore(_start) ? _start : v)),
                      ] else
                        Text('–', style: TextStyle(color: tt.textSecondary)),
                      pill(dayLabel(_end), () async {
                        final picked = await _pickDay(_end);
                        if (picked == null) return;
                        final end = _withDay(_end, picked);
                        setState(() => _end = end.isBefore(_start) ? _start : end);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _allDay,
                            onChanged: (v) => setState(() {
                              _allDay = v ?? false;
                              _reminders = {
                                for (final r in _reminders)
                                  if ((_allDay ? ReminderPresets.allDay : ReminderPresets.timed).contains(r)) r,
                              };
                            }),
                          ),
                          Text(
                            t.calendarAllDay,
                            style: TextStyle(fontSize: TtText.body, color: tt.text),
                          ),
                        ],
                      ),
                      PopupMenuButton<String?>(
                        tooltip: '',
                        onSelected: (rule) async {
                          if (rule != '*') {
                            setState(() => _rule = rule);
                            return;
                          }
                          // "Personalizar…": Google's "Repetição personalizada".
                          final picked = await showCustomRecurrence(
                            context,
                            start: _start,
                            initial: _rule,
                            firstWeekday: (ref.read(preferencesProvider).value ?? Preferences.defaults).firstWeekday,
                          );
                          if (picked != null && mounted) setState(() => _rule = picked);
                        },
                        itemBuilder: (_) => [
                          for (final e in repeats.entries) PopupMenuItem<String?>(value: e.key, height: 36, child: Text(e.value)),
                          PopupMenuItem<String?>(value: '*', height: 36, child: Text('${t.repeatCustom}…')),
                        ],
                        child: IgnorePointer(child: pill(ruleLabel, () {}, menu: true)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // "Detalhes" (Google's "Event details" tab).
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: tt.primary, width: 2)),
                      ),
                      child: Text(
                        t.calendarDetails,
                        style: TextStyle(fontWeight: FontWeight.w600, color: tt.primary),
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, color: tt.divider),
                const SizedBox(height: 8),
                section(
                  Icons.category_outlined,
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (kind, label) in [(TaskKind.text, t.calendarKindTask), (TaskKind.note, t.calendarKindNote)])
                        ChoiceChip(
                          label: Text(label),
                          selected: _kind == kind,
                          showCheckmark: false,
                          selectedColor: tt.primary,
                          labelStyle: TextStyle(fontSize: 13, color: _kind == kind ? Colors.white : tt.textSecondary),
                          onSelected: (_) => setState(() => _kind = kind),
                        ),
                    ],
                  ),
                ),
                section(
                  Icons.circle,
                  color: parseHexColor(_color) ?? parseHexColor(list?.color) ?? tt.primary,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: '',
                        onSelected: (id) => setState(() => _listId = id),
                        itemBuilder: (_) => [
                          for (final l in lists)
                            PopupMenuItem(
                              value: l.id,
                              height: 36,
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 12, color: parseHexColor(l.color) ?? tt.primary),
                                  const SizedBox(width: 10),
                                  Text(labels.listName(l)),
                                ],
                              ),
                            ),
                        ],
                        child: IgnorePointer(child: pill(list == null ? '' : labels.listName(list), () {}, menu: true)),
                      ),
                      // The color beside the calendar, as on Google's page.
                      Tooltip(
                        message: t.colorOfTask,
                        child: GestureDetector(
                          onTapUp: (d) async {
                            final picked = await showColorLabelMenu(context, near: d.globalPosition, current: _color);
                            if (picked case ColorPicked(:final color) when mounted) setState(() => _color = color);
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                              decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 18, color: parseHexColor(_color) ?? parseHexColor(list?.color) ?? tt.primary),
                                  Icon(Icons.arrow_drop_down, size: 20, color: tt.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                section(
                  Icons.notifications_none,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final r in _reminders)
                        InputChip(label: Text(reminderLabel(t, r)), onDeleted: () => setState(() => _reminders = {..._reminders}..remove(r))),
                      PopupMenuButton<String>(
                        tooltip: '',
                        onSelected: (r) => setState(() => _reminders = {..._reminders, r}),
                        itemBuilder: (_) => [
                          for (final r in presets)
                            if (!_reminders.contains(r)) PopupMenuItem(value: r, height: 36, child: Text(reminderLabel(t, r))),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Text(
                            t.calendarAddReminder,
                            style: TextStyle(color: tt.primary, fontSize: TtText.body),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                section(
                  _priority == Priority.none ? Icons.outlined_flag : Icons.flag,
                  color: _priority == Priority.none ? null : tt.priorityColor(_priority),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PopupMenuButton<Priority>(
                      tooltip: '',
                      onSelected: (p) => setState(() => _priority = p),
                      itemBuilder: (_) => [
                        for (final p in [Priority.high, Priority.medium, Priority.low, Priority.none])
                          PopupMenuItem(
                            value: p,
                            height: 36,
                            child: Row(
                              children: [
                                Icon(p == Priority.none ? Icons.outlined_flag : Icons.flag, size: 16, color: tt.priorityColor(p)),
                                const SizedBox(width: 10),
                                Text(labels.priority(p)),
                              ],
                            ),
                          ),
                      ],
                      child: IgnorePointer(child: pill(labels.priority(_priority), () {}, menu: true)),
                    ),
                  ),
                ),
                section(
                  Icons.notes,
                  TextField(
                    controller: _description,
                    minLines: 6,
                    maxLines: 14,
                    style: TextStyle(fontSize: TtText.body, color: tt.text),
                    decoration: InputDecoration(
                      hintText: t.calendarAddDescription,
                      hintStyle: TextStyle(color: tt.textTertiary),
                      filled: true,
                      fillColor: tt.fieldFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
