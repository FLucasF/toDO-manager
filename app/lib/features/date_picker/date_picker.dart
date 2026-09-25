import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../domain/custom_repeat.dart';
import '../../domain/quick_add.dart';
import '../../domain/recurrence.dart';
import '../../domain/reminders.dart';
import '../../l10n/app_localizations.dart';
import '../../core/time_zones.dart';
import '../common/feedback.dart';
import '../common/time_zone_picker.dart';
import 'custom_repeat_dialog.dart';
import 'month_calendar.dart';

/// Date, time, reminders and repetition chosen in the picker.
class DateSelection {
  const DateSelection({
    this.dueDate,
    this.startDate,
    this.isAllDay = true,
    this.reminders = const {},
    this.repeatRule,
    this.repeatFrom = RepeatFrom.dueDate,
    this.timeZone,
    this.isFloating = false,
  });

  /// Local date (midnight when [isAllDay]) or date and time; null = no date. With a duration, the end.
  final DateTime? dueDate;

  /// Start of a duration ("Duração" tab); null or equal to [dueDate] without one.
  final DateTime? startDate;
  final bool isAllDay;
  final Set<String> reminders;
  final String? repeatRule;
  final RepeatFrom repeatFrom;

  /// "Fuso horário fixo" (an IANA id; null = this device's), or [isFloating] for "Tempo flutuante"
  ///. The dates above are always instants on this device.
  final String? timeZone;
  final bool isFloating;

  /// The same selection with its times passed through [f] (all-day dates stay).
  DateSelection _mapTimes(DateTime Function(DateTime) f) => isAllDay || dueDate == null
      ? this
      : DateSelection(
          dueDate: f(dueDate!),
          startDate: startDate == null ? null : f(startDate!),
          isAllDay: isAllDay,
          reminders: reminders,
          repeatRule: repeatRule,
          repeatFrom: repeatFrom,
          timeZone: timeZone,
          isFloating: isFloating,
        );
}

/// TickTick's date picker: quick days, month calendar, time, reminders, repetition and its
/// end. Returns null when cancelled; "Limpar" returns a selection without a date.
///
/// [dateOnly] keeps just the date and time (a checklist item's reminder). [withZone]
/// adds the "Fuso horário" row ("Fuso horário" of Configurações → Data e hora); with a fixed zone the
/// picker shows and takes that zone's clock times.
Future<DateSelection?> showTtDatePicker(
  BuildContext context, {
  required DateSelection initial,
  required DateTime now,
  bool dateOnly = false,
  bool withZone = false,
}) async {
  final zone = initial.timeZone;
  final shown = zone == null ? initial : initial._mapTimes((d) => localToWall(d, zone));
  final picked = await showDialog<DateSelection>(
    context: context,
    builder: (_) => _DatePickerDialog(initial: shown, now: now, dateOnly: dateOnly, withZone: withZone),
  );
  final chosen = picked?.timeZone;
  return chosen == null || picked!.dueDate == null ? picked : picked._mapTimes((d) => wallToLocal(d, chosen));
}

/// TickTick's limit of reminders per task ("Múltiplos lembretes (até 5 por tarefa)").
const maxRemindersPerTask = 5;

// ------------------------------------------------------------------ rule helpers

/// Presets of the "Repetir" list for a given day.
Map<String, String> repeatPresets(AppLocalizations t, DateTime day) {
  final labels = DateLabels(t);
  final month = labels.monthShort(day);
  return {
    'FREQ=DAILY;INTERVAL=1': t.repeatDaily,
    'FREQ=WEEKLY;INTERVAL=1;BYDAY=${byDayCodes[day.weekday - 1]}': t.repeatWeekly(labels.weekday(day)),
    'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=${day.day}': t.repeatMonthly(day.day),
    'FREQ=YEARLY;INTERVAL=1;BYMONTH=${day.month};BYMONTHDAY=${day.day}': t.repeatYearly(day.day, month),
    'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR': t.repeatWeekdays,
  };
}

String _withoutEnd(String rule) => withoutExclusions(rule).split(';').where((p) => !p.startsWith('COUNT=') && !p.startsWith('UNTIL=')).join(';');

int? ruleCount(String rule) => int.tryParse(RegExp(r'COUNT=(\d+)').firstMatch(rule)?.group(1) ?? '');

DateTime? ruleUntil(String rule) {
  final m = RegExp(r'UNTIL=(\d{4})(\d{2})(\d{2})').firstMatch(rule);
  return m == null ? null : DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
}

String withEnd(String rule, {int? count, DateTime? until}) {
  final base = _withoutEnd(rule);
  if (count != null) return '$base;COUNT=$count';
  if (until != null) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$base;UNTIL=${until.year}${two(until.month)}${two(until.day)}T235959Z';
  }
  return base;
}

/// Label of a stored rule: its preset name or "Personalizado".
String repeatLabel(AppLocalizations t, String rule, DateTime day) => repeatPresets(t, day)[_withoutEnd(rule)] ?? t.repeatCustom;

String reminderLabel(AppLocalizations t, String trigger) => switch (trigger) {
  ReminderPresets.onTime => t.reminderOnTime,
  ReminderPresets.fiveMinutesBefore => t.reminder5m,
  ReminderPresets.thirtyMinutesBefore => t.reminder30m,
  ReminderPresets.oneHourBefore => t.reminder1h,
  ReminderPresets.oneDayBefore => t.reminder1d,
  ReminderPresets.onTheDay => t.reminderOnTheDay,
  ReminderPresets.oneDayBeforeAt9 => t.reminder1dAt9,
  ReminderPresets.twoDaysBeforeAt9 => t.reminder2dAt9,
  ReminderPresets.threeDaysBeforeAt9 => t.reminder3dAt9,
  ReminderPresets.oneWeekBeforeAt9 => t.reminder1wAt9,
  ReminderPresets.atEnd => t.reminderAtEnd,
  _ => _customReminderLabel(t, trigger),
};

String _customReminderLabel(AppLocalizations t, String trigger) {
  final d = parseTrigger(trigger).abs();
  if (d.inMinutes % (24 * 60) == 0) return t.reminderCustomValue(d.inDays, t.unitDays.toLowerCase());
  if (d.inMinutes % 60 == 0) return t.reminderCustomValue(d.inHours, t.unitHours.toLowerCase());
  return t.reminderCustomValue(d.inMinutes, t.unitMinutes.toLowerCase());
}

// ------------------------------------------------------------------ dialog

class _DatePickerDialog extends StatefulWidget {
  const _DatePickerDialog({required this.initial, required this.now, this.dateOnly = false, this.withZone = false});

  final DateSelection initial;
  final DateTime now;
  final bool dateOnly;
  final bool withZone;

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late DateTime? _day = widget.initial.dueDate == null ? null : startOfDay(widget.initial.dueDate!);
  late TimeOfDay? _time = widget.initial.dueDate == null || widget.initial.isAllDay ? null : TimeOfDay.fromDateTime(widget.initial.dueDate!);
  late Set<String> _reminders = {...widget.initial.reminders};
  late String? _rule = widget.initial.repeatRule;
  late RepeatFrom _from = widget.initial.repeatFrom;
  late String? _zone = widget.initial.timeZone;
  late bool _floating = widget.initial.isFloating;
  late DateTime _month = DateTime((_initialStart ?? widget.now).year, (_initialStart ?? widget.now).month);

  // "Duração" tab: [_day]/[_time] become the end and these hold the start.
  late bool _duration = _initialStart != null && widget.initial.dueDate != null && _initialStart!.isBefore(widget.initial.dueDate!);
  late DateTime? _startDay = _duration ? startOfDay(_initialStart!) : null;
  late TimeOfDay? _startTime = _duration && !widget.initial.isAllDay ? TimeOfDay.fromDateTime(_initialStart!) : null;
  bool _pickingEnd = false;

  DateTime? get _initialStart => widget.initial.startDate ?? widget.initial.dueDate;

  DateTime get _today => startOfDay(widget.now);

  /// Day the repetition counts from: the start of a duration, else the date.
  DateTime? get _anchorDay => _duration ? _startDay : _day;

  void _pickDay(DateTime day) => setState(() {
    _day = day;
    _month = DateTime(day.year, day.month);
  });

  /// Duration: the first tap sets the start (and end), the second the end.
  void _pickRangeDay(DateTime day) => setState(() {
    final start = _startDay;
    if (!_pickingEnd || start == null || day.isBefore(start)) {
      _startDay = day;
      _day = day;
      _pickingEnd = true;
    } else {
      _day = day;
      _pickingEnd = false;
    }
  });

  void _setDuration(bool duration) => setState(() {
    if (duration == _duration) return;
    _duration = duration;
    _pickingEnd = false;
    if (duration) {
      _startDay = _day ?? _today;
      _day = _startDay;
      _startTime = _time;
      final time = _time;
      if (time != null) _time = TimeOfDay(hour: (time.hour + 1) % 24, minute: time.minute);
    } else {
      _day = _startDay ?? _day;
      _time = _startTime;
      _startDay = null;
      _startTime = null;
    }
  });

  static DateTime _at(DateTime day, TimeOfDay? time) => time == null ? day : DateTime(day.year, day.month, day.day, time.hour, time.minute);

  DateSelection _result() {
    final day = _day;
    if (day == null) return const DateSelection();
    final time = _time;
    final end = _at(day, time);
    final start = _duration && _startDay != null ? _at(_startDay!, _startTime) : null;
    return DateSelection(
      dueDate: start != null && end.isBefore(start) ? start : end,
      startDate: start,
      isAllDay: time == null,
      reminders: _reminders,
      repeatRule: _rule,
      repeatFrom: _from,
      timeZone: _floating ? null : _zone,
      isFloating: _floating,
    );
  }

  /// "Sao Paulo, GMT-3" or "Tempo flutuante".
  String _zoneLabel(AppLocalizations t) {
    if (_floating) return t.zoneFloating;
    final zone = _zone ?? deviceZoneId();
    return zone == null ? localOffsetLabel(widget.now) : '${zoneCity(zone)}, ${zoneOffsetLabel(zone, widget.now)}';
  }

  Future<void> _pickZone() async {
    final picked = await showDialog<(String?, bool)>(
      context: context,
      builder: (_) => _ZoneDialog(zone: _zone, floating: _floating, now: widget.now),
    );
    if (picked == null) return;
    setState(() {
      final device = deviceZoneId();
      // This device's zone is the same as none.
      _zone = picked.$1 == device ? null : picked.$1;
      _floating = picked.$2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = DateLabels(t);
    final occurrences = _rule == null || _anchorDay == null
        ? const <DateTime>{}
        : upcomingOccurrences(rule: _rule!, from: _anchorDay!, limit: 60).map(startOfDay).toSet();

    Widget quick(IconData icon, String tooltip, DateTime day) => IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: tt.textSecondary),
      onPressed: () => _pickDay(day),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _tab(t.pickerTabDate, selected: !_duration, onTap: () => _setDuration(false)),
                  if (!widget.dateOnly) _tab(t.pickerTabDuration, selected: _duration, onTap: () => _setDuration(true)),
                ],
              ),
              const SizedBox(height: 6),
              if (!_duration)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    quick(Icons.wb_sunny_outlined, t.dateToday, _today),
                    quick(Icons.wb_twilight_outlined, t.dateTomorrow, _today.add(const Duration(days: 1))),
                    quick(Icons.next_week_outlined, t.dateNextWeek, _today.add(const Duration(days: 7))),
                    quick(Icons.nightlight_outlined, t.pickerNextMonth, DateTime(_today.year, _today.month + 1, _today.day)),
                  ],
                ),
              MonthCalendar(
                month: _month,
                today: _today,
                isSelected: _duration
                    ? (d) => _startDay != null && _day != null && !d.isBefore(_startDay!) && !d.isAfter(_day!)
                    : (d) => _day != null && daysBetween(d, _day!) == 0,
                occurrences: occurrences,
                title: labels.monthTitle(_month),
                onPrevious: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                onNext: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                onToday: () => setState(() => _month = DateTime(_today.year, _today.month)),
                onPick: _duration ? _pickRangeDay : _pickDay,
              ),
              const Divider(height: 16),
              if (_duration) ...[
                _row(
                  context,
                  icon: Icons.first_page,
                  label: t.pickerStart,
                  value: _rangeLabel(labels, _startDay, _startTime, t),
                  onTap: _startTime == null ? null : () => _pickRangeTime(start: true),
                ),
                _row(
                  context,
                  icon: Icons.last_page,
                  label: t.pickerEnd,
                  value: _rangeLabel(labels, _day, _time, t),
                  onTap: _time == null ? null : () => _pickRangeTime(start: false),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    t.pickerAllDay,
                    style: TextStyle(color: tt.text, fontSize: TtText.body),
                  ),
                  value: _time == null,
                  onChanged: (allDay) => setState(() {
                    if (allDay) {
                      _startTime = null;
                      _time = null;
                      _reminders = {};
                    } else {
                      final now = widget.now;
                      final next = (now.hour * 60 + now.minute + 29) ~/ 30 * 30 % (24 * 60);
                      _startTime = TimeOfDay(hour: next ~/ 60, minute: next % 60);
                      _time = TimeOfDay(hour: (next ~/ 60 + 1) % 24, minute: next % 60);
                      _reminders = {ReminderPresets.onTime};
                    }
                  }),
                ),
              ] else
                _row(
                  context,
                  icon: Icons.schedule,
                  label: t.pickerTime,
                  value: _time == null ? t.pickerNone : DateLabels.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute)),
                  onTap: _pickTime,
                  onClear: _time == null
                      ? null
                      : () => setState(() {
                          _time = null;
                          _reminders = {};
                        }),
                ),
              if (widget.withZone && (_time != null || _startTime != null))
                _row(context, icon: Icons.public, label: t.pickerTimeZone, value: _zoneLabel(t), onTap: _pickZone),
              if (!widget.dateOnly) ...[
                _row(
                  context,
                  icon: Icons.alarm,
                  label: t.pickerReminder,
                  value: switch (ReminderPresets.firing(_reminders).map((r) => reminderLabel(t, r)).join(', ')) {
                    '' => t.pickerNone,
                    final labels when _reminders.contains(ReminderPresets.constant) => '$labels · ${t.reminderConstant}',
                    final labels => labels,
                  },
                  onTap: _day == null ? null : _pickReminders,
                ),
                _row(
                  context,
                  icon: Icons.repeat,
                  label: t.pickerRepeat,
                  value: _rule == null ? t.pickerNone : repeatLabel(t, _rule!, _anchorDay ?? _today),
                  onTap: _day == null ? null : _pickRepeat,
                ),
                if (_rule != null && specificDates(_rule!) == null)
                  _row(
                    context,
                    icon: Icons.event_busy_outlined,
                    label: t.repeatEnds,
                    value: switch ((ruleCount(_rule!), ruleUntil(_rule!))) {
                      (final int c, _) => t.repeatTimesLeft(c),
                      (_, final DateTime u) => labels.detailDate(u, isAllDay: true, today: _today),
                      _ => t.repeatEndsNever,
                    },
                    onTap: _pickEnd,
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(context, const DateSelection()), child: Text(t.dateClear)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(onPressed: () => Navigator.pop(context, _result()), child: Text(t.actionOk)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, {required bool selected, required VoidCallback onTap}) {
    final tt = context.tt;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? tt.primary : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: selected ? tt.text : tt.textTertiary),
        ),
      ),
    );
  }

  String _rangeLabel(DateLabels labels, DateTime? day, TimeOfDay? time, AppLocalizations t) {
    if (day == null) return t.pickerNone;
    return labels.detailDate(_at(day, time), isAllDay: time == null, today: _today);
  }

  Future<void> _pickRangeTime({required bool start}) async {
    final current = start ? _startTime : _time;
    if (current == null) return;
    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _TimeDialog(initial: current),
    );
    if (picked == null) return;
    setState(() => start ? _startTime = picked : _time = picked);
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    final tt = context.tt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tt.textSecondary),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tt.text, fontSize: TtText.body),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.close, size: 14, color: tt.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    // The list opens on the chosen time, or on the next half hour.
    final now = widget.now;
    final next = (now.hour * 60 + now.minute + 29) ~/ 30 * 30 % (24 * 60);
    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _TimeDialog(
        initial: _time ?? TimeOfDay(hour: next ~/ 60, minute: next % 60),
      ),
    );
    if (picked == null) return;
    setState(() {
      final wasAllDay = _time == null;
      _time = picked;
      _day ??= _today;
      // Setting a time applies the default "Na hora" reminder.
      if (wasAllDay) _reminders = {ReminderPresets.onTime};
    });
  }

  Future<void> _pickReminders() async {
    final t = AppLocalizations.of(context);
    // A duration adds "No fim".
    final presets = [...(_time == null ? ReminderPresets.allDay : ReminderPresets.timed), if (_duration) ReminderPresets.atEnd];
    final selected = {..._reminders};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.pickerReminder, style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final trigger in ReminderPresets.firing({...presets, ...selected}))
                  CheckboxListTile(
                    dense: true,
                    value: selected.contains(trigger),
                    title: Text(reminderLabel(t, trigger)),
                    // Up to 5 reminders per task.
                    onChanged: selected.contains(trigger) || ReminderPresets.firing(selected).length < maxRemindersPerTask
                        ? (v) => setState(() => v == true ? selected.add(trigger) : selected.remove(trigger))
                        : null,
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.add, size: 18),
                  title: Text(t.reminderCustom),
                  enabled: ReminderPresets.firing(selected).length < maxRemindersPerTask,
                  onTap: () async {
                    final custom = await _customReminder(context);
                    if (custom != null) setState(() => selected.add(custom));
                  },
                ),
                // "Lembrete constante" of this task: its notifications stay until dismissed.
                SwitchListTile(
                  dense: true,
                  title: Text(t.reminderConstant),
                  value: selected.contains(ReminderPresets.constant),
                  onChanged: (v) => setState(() => v ? selected.add(ReminderPresets.constant) : selected.remove(ReminderPresets.constant)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: Text(t.actionOk)),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _reminders = result);
  }

  Future<String?> _customReminder(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final value = TextEditingController(text: '15');
    var unit = 0; // 0 minutes, 1 hours, 2 days
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(t.reminderCustom, style: const TextStyle(fontSize: 15)),
          content: Row(
            children: [
              SizedBox(
                width: 70,
                child: TextField(controller: value, keyboardType: TextInputType.number, autofocus: true),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: unit,
                items: [
                  DropdownMenuItem(value: 0, child: Text(t.unitMinutes)),
                  DropdownMenuItem(value: 1, child: Text(t.unitHours)),
                  DropdownMenuItem(value: 2, child: Text(t.unitDays)),
                ],
                onChanged: (v) => setState(() => unit = v ?? 0),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(value.text.trim());
                if (n == null || n <= 0) return;
                final d = switch (unit) {
                  0 => Duration(minutes: n),
                  1 => Duration(hours: n),
                  _ => Duration(days: n),
                };
                Navigator.pop(context, formatTrigger(-d));
              },
              child: Text(t.actionOk),
            ),
          ],
        ),
      ),
    );
    value.dispose();
    return result;
  }

  Future<void> _pickRepeat() async {
    final t = AppLocalizations.of(context);
    final day = _anchorDay ?? _today;
    final presets = repeatPresets(t, day);
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width / 2, box.size.height * 0.6));
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        PopupMenuItem(value: '', height: 36, child: Text(t.pickerNone)),
        for (final p in presets.entries) PopupMenuItem(value: p.key, height: 36, child: Text(p.value)),
        PopupMenuItem(value: 'custom', height: 36, child: Text(t.repeatCustom)),
      ],
    );
    if (!mounted || picked == null) return;
    if (picked.isEmpty) {
      setState(() => _rule = null);
    } else if (picked == 'custom') {
      final custom = await showCustomRepeatDialog(context, rule: _rule, from: _from, day: day, now: widget.now);
      if (custom == null || !mounted) return;
      final previous = _rule;
      final dates = specificDates(custom.rule);
      setState(() {
        // Keep "A repetição termina" when switching between RRULEs.
        _rule = dates == null && previous != null ? withEnd(custom.rule, count: ruleCount(previous), until: ruleUntil(previous)) : custom.rule;
        _from = custom.from;
        // Specific dates: the task moves to the first chosen date from today on.
        if (dates != null && !dates.any((d) => daysBetween(d, day) == 0)) {
          final first = dates.where((d) => !d.isBefore(_today)).firstOrNull ?? dates.first;
          _day = first;
          _month = DateTime(first.year, first.month);
        }
      });
    } else {
      setState(() {
        _rule = picked;
        _from = RepeatFrom.dueDate;
      });
    }
  }

  Future<void> _pickEnd() async {
    final t = AppLocalizations.of(context);
    final rule = _rule;
    if (rule == null) return;
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset(box.size.width / 2, box.size.height * 0.7));
    final picked = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(origin.dx, origin.dy, origin.dx + 1, origin.dy + 1),
      items: [
        PopupMenuItem(value: 0, height: 36, child: Text(t.repeatEndsNever)),
        PopupMenuItem(value: 1, height: 36, child: Text(t.repeatEndsOnDate)),
        PopupMenuItem(value: 2, height: 36, child: Text(t.repeatEndsAfterCount)),
      ],
    );
    if (!mounted) return;
    switch (picked) {
      case 0:
        setState(() => _rule = withEnd(rule));
      case 1:
        final until = await showDatePicker(
          context: context,
          initialDate: (_day ?? _today).add(const Duration(days: 30)),
          firstDate: _day ?? _today,
          lastDate: DateTime(_today.year + 20),
        );
        if (until != null) setState(() => _rule = withEnd(rule, until: until));
      case 2:
        final text = await promptText(context, title: t.repeatEndsAfterCount, initial: '${ruleCount(rule) ?? 5}', hint: t.repeatTimesHint);
        final n = int.tryParse(text ?? '');
        if (n != null && n > 0) setState(() => _rule = withEnd(rule, count: n));
    }
  }
}

/// The "Hora" dialog on its own (also used by the daily alert setting).
Future<TimeOfDay?> showTimeDialog(BuildContext context, {required TimeOfDay initial}) => showDialog<TimeOfDay>(
  context: context,
  builder: (_) => _TimeDialog(initial: initial),
);

/// "Hora": an editable field ("14:30", "14h", "2pm") above the list of times every 30 minutes.
class _TimeDialog extends StatefulWidget {
  const _TimeDialog({required this.initial});

  final TimeOfDay initial;

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  static const _rowHeight = 36.0;
  late final _text = TextEditingController(text: _format(widget.initial));
  late final _scroll = ScrollController(initialScrollOffset: ((widget.initial.hour * 2 + widget.initial.minute ~/ 30) - 2).clamp(0, 48) * _rowHeight);
  bool _invalid = false;

  static String _format(TimeOfDay t) => DateLabels.time(DateTime(2000, 1, 1, t.hour, t.minute));

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = parseTime(_text.text);
    if (parsed == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, TimeOfDay(hour: parsed.hour, minute: parsed.minute));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    return AlertDialog(
      title: Text(t.pickerTime, style: const TextStyle(fontSize: 15)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _text,
              autofocus: true,
              style: TextStyle(color: _invalid ? tt.overdue : tt.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: tt.fieldFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
              onChanged: (_) => setState(() => _invalid = false),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _rowHeight * 6,
              child: ListView.builder(
                controller: _scroll,
                itemExtent: _rowHeight,
                itemCount: 48,
                itemBuilder: (context, i) {
                  final time = TimeOfDay(hour: i ~/ 2, minute: i.isOdd ? 30 : 0);
                  return InkWell(
                    onTap: () => Navigator.pop(context, time),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(_format(time), style: TextStyle(color: time == widget.initial ? tt.primary : tt.text)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: _submit, child: Text(t.actionOk)),
      ],
    );
  }
}

/// "Fuso horário" of a task with a time: a fixed zone (a city), or "Tempo flutuante",
/// which keeps the clock time when this device changes zone. Pops (zone, floating).
class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({required this.zone, required this.floating, required this.now});

  final String? zone;
  final bool floating;
  final DateTime now;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late String? _zone = widget.zone ?? deviceZoneId();
  late bool _floating = widget.floating;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final zone = _zone;
    return AlertDialog(
      title: Text(t.pickerTimeZone, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 320,
        child: RadioGroup<bool>(
          groupValue: _floating,
          onChanged: (v) => setState(() => _floating = v ?? false),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                value: false,
                contentPadding: EdgeInsets.zero,
                title: Text(t.zoneFixed),
                subtitle: Text(
                  zone == null ? localOffsetLabel(widget.now) : '${zoneCity(zone)}, ${zoneOffsetLabel(zone, widget.now)}',
                  style: TextStyle(color: tt.textTertiary),
                ),
                secondary: TextButton(
                  onPressed: () async {
                    final picked = await pickTimeZone(context, widget.now);
                    if (picked != null) {
                      setState(() {
                        _zone = picked;
                        _floating = false;
                      });
                    }
                  },
                  child: Text(t.zoneChoose),
                ),
              ),
              RadioListTile<bool>(
                value: true,
                contentPadding: EdgeInsets.zero,
                title: Text(t.zoneFloating),
                subtitle: Text(t.zoneFloatingHint, style: TextStyle(color: tt.textTertiary)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, (_floating ? null : _zone, _floating)), child: Text(t.actionOk)),
      ],
    );
  }
}
