import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/custom_repeat.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations.dart';
import '../date_picker/date_picker.dart';

/// "na quarta sexta-feira" / "no último sábado": the [nth] (-1 = last) [weekday] of a month.
String weekdayOfMonth(AppLocalizations t, DateLabels dates, int nth, int weekday) {
  final masculine = weekday == DateTime.saturday || weekday == DateTime.sunday;
  final name = dates.weekday(DateTime(2024, 1, weekday)).toLowerCase(); // 2024-01-01 was a Monday.
  final ordinals = (masculine ? t.ordinalsMasculine : t.ordinalsFeminine).split(',');
  final which = nth < 0 ? (masculine ? t.lastMasculine : t.lastFeminine) : ordinals[(nth - 1).clamp(0, ordinals.length - 1)];
  return '${masculine ? t.inMasculine : t.inFeminine} $which $name';
}

/// A rule in words, as Google shows it: "Semanal: segunda-feira, quarta-feira, 13 vezes",
/// "A cada 2 meses, até 20 de dez. de 2026".
String recurrenceSummary(AppLocalizations t, DateLabels dates, String rule, DateTime day) {
  final draft = CustomRepeatDraft.fromRule(rule, RepeatFrom.dueDate, day);
  final n = draft.interval;
  String dayNames() => [
    for (var d = 1; d <= 7; d++)
      if (draft.weekdays.contains(d)) dates.weekday(DateTime(2024, 1, d)).toLowerCase(),
  ].join(', ');
  final base = switch (draft.unit) {
    RepeatUnit.day => n == 1 ? t.repeatDaily : t.recurrenceEveryN(n, t.recurrenceDays(n)),
    RepeatUnit.week => n == 1 ? t.recurrenceWeeklyOn(dayNames()) : '${t.recurrenceEveryN(n, t.recurrenceWeeks(n))}: ${dayNames()}',
    RepeatUnit.month when n > 1 => t.recurrenceEveryN(n, t.recurrenceMonths(n)),
    RepeatUnit.month => switch (draft.monthlyKind) {
      MonthlyKind.onWeekday => t.repeatMonthlyOn(weekdayOfMonth(t, dates, draft.ordinal, draft.weekday)),
      _ => t.repeatMonthly(draft.monthDay),
    },
    RepeatUnit.year =>
      n == 1
          ? t.recurrenceYearlyOn('${draft.monthDay} de ${dates.monthLong(DateTime(2024, draft.month)).toLowerCase()}')
          : t.recurrenceEveryN(n, t.recurrenceYears(n)),
  };
  if (ruleCount(rule) case final count?) return '$base, ${t.recurrenceTimes(count)}';
  if (ruleUntil(rule) case final until?) return '$base, ${t.recurrenceUntil('${until.day} de ${dates.monthShort(until)}. de ${until.year}')}';
  return base;
}

enum _Ends { never, onDate, after }

/// Google Calendar's "Repetição personalizada": repeat every N days / weeks / months / years, on which
/// weekdays (or which day of the month), and when it ends (never, on a date, after N occurrences).
/// Returns the rule, or null when cancelled.
Future<String?> showCustomRecurrence(BuildContext context, {required DateTime start, String? initial, int firstWeekday = DateTime.sunday}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _RecurrenceDialog(start: start, initial: initial, firstWeekday: firstWeekday),
    );

class _RecurrenceDialog extends StatefulWidget {
  const _RecurrenceDialog({required this.start, required this.initial, required this.firstWeekday});

  final DateTime start;
  final String? initial;
  final int firstWeekday;

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late final CustomRepeatDraft _draft = () {
    final d = CustomRepeatDraft.fromRule(widget.initial, RepeatFrom.dueDate, widget.start);
    // Without a rule, Google starts on "1 semana" on the start's weekday.
    if (widget.initial == null) d.unit = RepeatUnit.week;
    return d;
  }();
  late final _interval = TextEditingController(text: '${_draft.interval}');
  late final _count = TextEditingController(text: '${ruleCount(widget.initial ?? '') ?? 13}');
  late _Ends _ends = widget.initial == null
      ? _Ends.never
      : (ruleCount(widget.initial!) != null ? _Ends.after : (ruleUntil(widget.initial!) != null ? _Ends.onDate : _Ends.never));
  late DateTime _until = ruleUntil(widget.initial ?? '') ?? DateTime(widget.start.year, widget.start.month + 3, widget.start.day);

  @override
  void dispose() {
    _interval.dispose();
    _count.dispose();
    super.dispose();
  }

  String _result() {
    _draft.interval = (int.tryParse(_interval.text) ?? 1).clamp(1, 999);
    if (_draft.unit == RepeatUnit.week && _draft.weekdays.isEmpty) _draft.weekdays = {widget.start.weekday};
    final rule = _draft.toRule()!;
    return switch (_ends) {
      _Ends.never => rule,
      _Ends.onDate => withEnd(rule, until: _until),
      _Ends.after => withEnd(rule, count: (int.tryParse(_count.text) ?? 1).clamp(1, 999)),
    };
  }

  /// A number field with ▲ ▼, as Google's.
  Widget _number(TextEditingController c, {String? suffix, bool enabled = true}) {
    final tt = context.tt;
    void step(int by) => setState(() => c.text = '${((int.tryParse(c.text) ?? 1) + by).clamp(1, 999)}');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: suffix == null ? 52 : 150,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                child: TextField(
                  controller: c,
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none, filled: false),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (suffix != null)
                Flexible(
                  child: Text(
                    suffix,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: enabled ? tt.textSecondary : tt.textTertiary),
                  ),
                ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled ? () => step(1) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_drop_up, size: 22, color: tt.textSecondary),
              ),
            ),
            InkWell(
              onTap: enabled ? () => step(-1) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_drop_down, size: 22, color: tt.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final n = int.tryParse(_interval.text) ?? 1;
    final start = widget.start;
    final place = weekdayInMonth(start);
    final label = TextStyle(fontSize: TtText.body, color: tt.textSecondary);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(text, style: label),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(t.recurrenceTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(t.recurrenceEvery, style: label),
                const SizedBox(width: 8),
                _number(_interval),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(4)),
                    child: DropdownButton<RepeatUnit>(
                      value: _draft.unit,
                      icon: Icon(Icons.arrow_drop_down, color: tt.textSecondary),
                      onChanged: (u) => setState(() => _draft.unit = u ?? _draft.unit),
                      items: [
                        DropdownMenuItem(value: RepeatUnit.day, child: Text(t.recurrenceDays(n))),
                        DropdownMenuItem(value: RepeatUnit.week, child: Text(t.recurrenceWeeks(n))),
                        DropdownMenuItem(value: RepeatUnit.month, child: Text(t.recurrenceMonths(n))),
                        DropdownMenuItem(value: RepeatUnit.year, child: Text(t.recurrenceYears(n))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_draft.unit == RepeatUnit.week) ...[
              heading(t.recurrenceOn),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Builder(
                      builder: (context) {
                        final weekday = (widget.firstWeekday - 1 + i) % 7 + 1;
                        final on = _draft.weekdays.contains(weekday);
                        final name = dates.weekday(DateTime(2024, 1, weekday));
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: name,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => setState(() {
                                on ? _draft.weekdays.remove(weekday) : _draft.weekdays.add(weekday);
                              }),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: on ? tt.primary : tt.fieldFill),
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: on ? Colors.white : tt.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
            if (_draft.unit == RepeatUnit.month) ...[
              const SizedBox(height: 16),
              DropdownButtonHideUnderline(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(4)),
                  child: DropdownButton<int>(
                    // 0 = on the day of the month; otherwise the nth weekday (-1 = last).
                    value: _draft.monthlyKind == MonthlyKind.onWeekday ? _draft.ordinal : 0,
                    icon: Icon(Icons.arrow_drop_down, color: tt.textSecondary),
                    onChanged: (v) => setState(() {
                      if (v == null || v == 0) {
                        _draft
                          ..monthlyKind = MonthlyKind.each
                          ..monthDay = start.day
                          ..monthDays = {start.day};
                      } else {
                        _draft
                          ..monthlyKind = MonthlyKind.onWeekday
                          ..ordinal = v
                          ..weekday = start.weekday;
                      }
                    }),
                    items: [
                      DropdownMenuItem(value: 0, child: Text(t.repeatMonthly(start.day))),
                      if (place.nth <= 4)
                        DropdownMenuItem(value: place.nth, child: Text(t.repeatMonthlyOn(weekdayOfMonth(t, dates, place.nth, start.weekday)))),
                      if (place.last) DropdownMenuItem(value: -1, child: Text(t.repeatMonthlyOn(weekdayOfMonth(t, dates, -1, start.weekday)))),
                    ],
                  ),
                ),
              ),
            ],
            heading(t.recurrenceEnds),
            RadioGroup<_Ends>(
              groupValue: _ends,
              onChanged: (v) => setState(() => _ends = v ?? _ends),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EndRow(value: _Ends.never, label: t.recurrenceNever, onSelect: () => setState(() => _ends = _Ends.never)),
                  _EndRow(
                    value: _Ends.onDate,
                    label: t.recurrenceOnDate,
                    onSelect: () => setState(() => _ends = _Ends.onDate),
                    trailing: InkWell(
                      onTap: _ends != _Ends.onDate
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _until,
                                firstDate: start,
                                lastDate: DateTime(start.year + 30),
                              );
                              if (picked != null && mounted) setState(() => _until = picked);
                            },
                      child: Container(
                        height: 40,
                        width: 136,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          '${_until.day} de ${dates.monthShort(_until)}. de ${_until.year}',
                          style: TextStyle(color: _ends == _Ends.onDate ? tt.text : tt.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  _EndRow(
                    value: _Ends.after,
                    label: t.recurrenceAfter,
                    onSelect: () => setState(() => _ends = _Ends.after),
                    trailing: _number(_count, suffix: t.recurrenceOccurrences(int.tryParse(_count.text) ?? 1), enabled: _ends == _Ends.after),
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
          style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 24)),
          onPressed: () => Navigator.pop(context, _result()),
          child: Text(t.recurrenceDone),
        ),
      ],
    );
  }
}

class _EndRow extends StatelessWidget {
  const _EndRow({required this.value, required this.label, required this.onSelect, this.trailing});

  final _Ends value;
  final String label;

  /// A click on the label also picks the option.
  final VoidCallback onSelect;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<_Ends>(value: value),
              SizedBox(
                width: 64,
                child: Text(label, style: TextStyle(color: context.tt.text)),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
