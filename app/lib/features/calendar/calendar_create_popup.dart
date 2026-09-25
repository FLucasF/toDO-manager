import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ids.dart';
import '../../domain/enums.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';
import '../date_picker/date_picker.dart';
import 'calendar_edit_page.dart';

/// Google Calendar's quick-create card: a big title, the kind
/// (Tarefa | Nota), the date line (opens the date picker: time, all day, repetition, reminders), a
/// description, the list and "Mais opções" / "Salvar". It opens by the clicked spot, or centered, and
/// its handle drags it. [onDraft] follows the date, so the grid can show the provisional block.
Future<void> showCalendarCreatePopup(
  BuildContext context, {
  required DateSelection schedule,
  Offset? near,
  required void Function(TaskDraft draft) onMoreOptions,
  required ValueChanged<DateSelection?> onDraft,
}) async {
  onDraft(schedule);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (context, _, _) => _CreatePopup(schedule: schedule, near: near, onMoreOptions: onMoreOptions, onDraft: onDraft),
  );
  onDraft(null);
}

class _CreatePopup extends ConsumerStatefulWidget {
  const _CreatePopup({required this.schedule, required this.near, required this.onMoreOptions, required this.onDraft});

  final DateSelection schedule;
  final Offset? near;
  final void Function(TaskDraft draft) onMoreOptions;
  final ValueChanged<DateSelection?> onDraft;

  @override
  ConsumerState<_CreatePopup> createState() => _CreatePopupState();
}

class _CreatePopupState extends ConsumerState<_CreatePopup> {
  static const _width = 448.0;
  static const _height = 390.0;

  final _title = TextEditingController();
  final _description = TextEditingController();
  late DateSelection _schedule = widget.schedule;
  TaskKind _kind = TaskKind.text;
  String _listId = inboxListId;

  /// Where the card is; null until placed by the click, then moved by the handle.
  Offset? _at;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Offset _initialPosition(Size screen) {
    final near = widget.near;
    if (near == null) return Offset((screen.width - _width) / 2, math.max(40, (screen.height - _height) / 2));
    // Beside the click (right if there is room, else left), kept on screen.
    final left = near.dx + 16 + _width <= screen.width ? near.dx + 16 : near.dx - 16 - _width;
    return Offset(left.clamp(8, math.max(8, screen.width - _width - 8)), (near.dy - 80).clamp(8, math.max(8, screen.height - _height - 8)));
  }

  Future<void> _pickDate() async {
    final picked = await showTtDatePicker(context, initial: _schedule, now: ref.read(clockProvider).now());
    if (picked == null || !mounted) return;
    setState(() => _schedule = picked);
    widget.onDraft(picked);
  }

  Future<String?> _save() async {
    if (_saving) return null;
    _saving = true;
    final s = _schedule;
    final id = await ref
        .read(repositoryProvider)
        .createTask(
          listId: _listId,
          title: _title.text.trim(),
          content: _description.text.trim(),
          dueDate: s.dueDate,
          startDate: s.startDate,
          isAllDay: s.isAllDay,
          kind: _kind,
          reminders: s.reminders,
          repeatRule: s.repeatRule,
          repeatFrom: s.repeatFrom,
        );
    if (mounted) Navigator.pop(context);
    return id;
  }

  /// "Sexta-feira, 25 de setembro · 15:00 – 16:00", or the day alone for an all-day task.
  String _when(AppLocalizations t, DateLabels dates) {
    final due = _schedule.dueDate;
    if (due == null) return t.calendarNoDate;
    final start = _schedule.startDate ?? due;
    final day = '${dates.weekday(start)}, ${start.day} de ${dates.monthLong(start).toLowerCase()}';
    if (_schedule.isAllDay) return day;
    final hours = _schedule.startDate == null ? DateLabels.time(due) : '${DateLabels.time(start)} – ${DateLabels.time(due)}';
    return '$day · $hours';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final labels = Labels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final lists = s.activeLists;
    final list = s.listById[_listId];
    final screen = MediaQuery.sizeOf(context);
    // Phones: the card takes the width and sits at the top, above the keyboard.
    final compact = screen.width < _width + 32;
    final width = compact ? screen.width - 16 : _width;
    final at = compact ? Offset(8, MediaQuery.paddingOf(context).top + 8) : (_at ?? _initialPosition(screen));
    final maxHeight = math.max(160.0, screen.height - MediaQuery.viewInsetsOf(context).bottom - at.dy - 8);
    final rule = _schedule.repeatRule;
    final repeat = rule == null || _schedule.dueDate == null ? t.calendarNoRepeat : repeatLabel(t, rule, _schedule.dueDate!);
    final reminders = _schedule.reminders.map((r) => reminderLabel(t, r)).join(', ');

    Widget line(IconData icon, Widget child, {Color? iconColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 40, child: Icon(icon, size: 20, color: iconColor ?? tt.textSecondary)),
          Expanded(child: child),
        ],
      ),
    );

    final card = Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 6,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tt.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, minWidth: width, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // The handle: drags the card away from what it covers (not on phones, where it is fixed).
                  if (!compact)
                    MouseRegion(
                      cursor: SystemMouseCursors.move,
                      child: GestureDetector(
                        onPanUpdate: (d) => setState(() => _at = (_at ?? at) + d.delta),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle, size: 18, color: tt.textTertiary),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: t.actionClose,
                    icon: Icon(Icons.close, size: 20, color: tt.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 12, 0),
                child: TextField(
                  controller: _title,
                  autofocus: true,
                  style: TextStyle(fontSize: 22, color: tt.text),
                  decoration: InputDecoration(
                    hintText: t.calendarAddTitle,
                    hintStyle: TextStyle(fontSize: 22, color: tt.textTertiary),
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: tt.divider)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tt.primary, width: 2)),
                  ),
                  onSubmitted: (_) => unawaited(_save()),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Wrap(
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
              const SizedBox(height: 8),
              line(
                Icons.schedule,
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => unawaited(_pickDate()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _when(t, dates),
                          style: TextStyle(fontSize: TtText.body, color: tt.text),
                        ),
                        Text(
                          _schedule.isAllDay && _schedule.dueDate != null ? '${t.calendarAllDay} • $repeat' : repeat,
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              line(
                Icons.notes,
                TextField(
                  controller: _description,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(fontSize: TtText.body, color: tt.text),
                  decoration: InputDecoration(
                    hintText: t.calendarAddDescription,
                    hintStyle: TextStyle(color: tt.textTertiary),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              line(
                Icons.circle,
                iconColor: parseHexColor(list?.color) ?? tt.primary,
                Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<String>(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            list == null ? '' : labels.listName(list),
                            style: TextStyle(fontSize: TtText.body, color: tt.text),
                          ),
                          Icon(Icons.arrow_drop_down, color: tt.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              line(
                Icons.notifications_none,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    reminders.isEmpty ? t.calendarNoReminder : reminders,
                    style: TextStyle(fontSize: TtText.body, color: tt.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    // As Google's: the full page with what is typed so far, saved there.
                    onPressed: () {
                      final draft = TaskDraft(title: _title.text, description: _description.text, kind: _kind, listId: _listId, schedule: _schedule);
                      Navigator.pop(context);
                      widget.onMoreOptions(draft);
                    },
                    child: Text(t.calendarMoreOptions),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24)),
                    onPressed: () => unawaited(_save()),
                    child: Text(t.actionSave),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [Positioned(left: at.dx, top: at.dy, child: card)],
    );
  }
}
