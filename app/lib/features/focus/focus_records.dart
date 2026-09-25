import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/focus_controller.dart' show focusDuration;
import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/focus.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';
import '../statistics/charts.dart';
import 'focus_page.dart' show focusRecordsProvider, showFocusRecordForm;
import 'focus_timers.dart' show focusLinkName;

String _time(AppLocalizations t, int seconds) => focusDuration(
  Duration(seconds: seconds),
  hours: t.focusHours,
  minutes: t.focusMins,
);

// ------------------------------------------------------------------ export

/// "Exportar" of "Foco em registro.": one row per record, `;` separated with a BOM,
/// as the habits export.
String focusCsv(AppLocalizations t, Snapshot s, List<FocusRecord> records, List<FocusTimer> timers) {
  String cell(Object? v) {
    final text = '${v ?? ''}';
    return text.contains(RegExp('[;"\n]')) ? '"${text.replaceAll('"', '""')}"' : text;
  }

  String at(DateTime d) => '${DateLabels.numeric(d.toLocal())} ${DateLabels.time(d.toLocal())}';
  final rows = <List<Object?>>[
    [t.focusExportStart, t.focusExportEnd, t.focusExportMinutes, t.focusExportMode, t.focusExportLinked, t.focusExportTimer, t.focusExportNote],
    for (final r in [...records]..sort((a, b) => a.startedAt.compareTo(b.startedAt)))
      if (r.deletedAt == null)
        [
          at(r.startedAt),
          at(r.endedAt),
          (r.seconds / 60).round(),
          r.mode == FocusMode.pomo ? t.focusTabPomo : t.focusTabStopwatch,
          focusLinkName(t, s, r.taskId),
          timers.where((x) => x.id == r.timerId).firstOrNull?.name,
          r.note,
        ],
  ];
  return rows.map((r) => r.map(cell).join(';')).join('\r\n');
}

/// Saves the records where the user picks, as `Focus_AAAAMMDD.csv`.
Future<void> exportFocusRecords(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final records = ref.read(focusRecordsProvider).value ?? const <FocusRecord>[];
  final timers = ref.read(preferencesProvider).value?.focusTimers ?? const <FocusTimer>[];
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(focusCsv(t, s, records, timers))]);
  final day = startOfDay(ref.read(clockProvider).now());
  String two(int n) => n.toString().padLeft(2, '0');
  final name = 'Focus_${day.year}${two(day.month)}${two(day.day)}.csv';
  final path = await FilePicker.platform.saveFile(fileName: name, bytes: bytes, type: FileType.custom, allowedExtensions: ['csv']);
  if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  if (path != null && context.mounted) showToast(context, t.focusExported);
}

// ------------------------------------------------------------------ batch management

enum _DateFilter { all, today, week, month }

enum _LengthFilter { all, short, long }

enum _LinkFilter { all, linked, unlinked }

/// "Gestão de Lotes": filters Data · Duração · Status Vinculado, a check box per day
/// and per record, "Selecionar Tudo", and deleting the selected ones.
Future<void> showFocusBatch(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _FocusBatch());

class _FocusBatch extends ConsumerStatefulWidget {
  const _FocusBatch();

  @override
  ConsumerState<_FocusBatch> createState() => _FocusBatchState();
}

class _FocusBatchState extends ConsumerState<_FocusBatch> {
  _DateFilter _date = _DateFilter.all;
  _LengthFilter _length = _LengthFilter.all;
  _LinkFilter _link = _LinkFilter.all;
  final Set<String> _selected = {};

  bool _passes(FocusRecord r, DateTime today) {
    final day = startOfDay(r.startedAt.toLocal());
    final dateOk = switch (_date) {
      _DateFilter.all => true,
      _DateFilter.today => day == today,
      _DateFilter.week => !day.isBefore(startOfWeek(today)),
      _DateFilter.month => day.year == today.year && day.month == today.month,
    };
    final lengthOk = switch (_length) {
      _LengthFilter.all => true,
      _LengthFilter.short => r.seconds < 25 * 60,
      _LengthFilter.long => r.seconds >= 25 * 60,
    };
    final linkOk = switch (_link) {
      _LinkFilter.all => true,
      _LinkFilter.linked => r.taskId != null,
      _LinkFilter.unlinked => r.taskId == null,
    };
    return dateOk && lengthOk && linkOk;
  }

  Widget _filter<T>(String label, T value, Map<T, String> options, ValueChanged<T> onChanged) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label: ',
        style: TextStyle(fontSize: TtText.small, color: context.tt.textTertiary),
      ),
      DropdownButton<T>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: TtText.small, color: context.tt.text),
        items: [for (final o in options.entries) DropdownMenuItem(value: o.key, child: Text(o.value))],
        onChanged: (v) => setState(() {
          if (v != null) onChanged(v);
          _selected.clear();
        }),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    final today = startOfDay(ref.watch(clockProvider).now());
    final records = [
      for (final r in ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[])
        if (r.deletedAt == null && _passes(r, today)) r,
    ];
    final byDay = <DateTime, List<FocusRecord>>{};
    for (final r in records) {
      (byDay[startOfDay(r.startedAt.toLocal())] ??= []).add(r);
    }
    bool? tri(Iterable<String> ids) {
      final chosen = ids.where(_selected.contains).length;
      return chosen == 0 ? false : (chosen == ids.length ? true : null);
    }

    void toggle(Iterable<String> ids, bool? on) => setState(() => on == true ? _selected.addAll(ids) : _selected.removeAll(ids));
    final all = [for (final r in records) r.id];
    return AlertDialog(
      title: Text(t.focusBatch, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 520,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 16,
              children: [
                _filter(t.focusFilterDate, _date, {
                  _DateFilter.all: t.searchAll,
                  _DateFilter.today: t.filterDateToday,
                  _DateFilter.week: t.filterDateThisWeek,
                  _DateFilter.month: t.filterDateThisMonth,
                }, (v) => _date = v),
                _filter(t.focusFilterLength, _length, {
                  _LengthFilter.all: t.searchAll,
                  _LengthFilter.short: t.focusLengthShort,
                  _LengthFilter.long: t.focusLengthLong,
                }, (v) => _length = v),
                _filter(t.focusFilterLinked, _link, {
                  _LinkFilter.all: t.searchAll,
                  _LinkFilter.linked: t.focusLinked,
                  _LinkFilter.unlinked: t.focusUnlinked,
                }, (v) => _link = v),
              ],
            ),
            const Divider(),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Text(t.focusRecordsEmpty, style: TextStyle(color: tt.textTertiary)),
                    )
                  : ListView(
                      children: [
                        for (final e in byDay.entries) ...[
                          CheckboxListTile(
                            dense: true,
                            tristate: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: tri([for (final r in e.value) r.id]),
                            onChanged: (v) => toggle([for (final r in e.value) r.id], v ?? false),
                            title: Text(
                              '${e.key.day} ${dates.monthShort(e.key)}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: tt.textSecondary),
                            ),
                          ),
                          for (final r in e.value)
                            CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.only(left: 32),
                              value: _selected.contains(r.id),
                              onChanged: (v) => toggle([r.id], v),
                              title: Text('${DateLabels.time(r.startedAt.toLocal())} - ${DateLabels.time(r.endedAt.toLocal())}'),
                              subtitle: focusLinkName(t, s, r.taskId) == null ? null : Text(focusLinkName(t, s, r.taskId)!),
                              secondary: Text(_time(t, r.seconds), style: TextStyle(color: tt.textSecondary)),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Checkbox(tristate: true, value: all.isEmpty ? false : tri(all), onChanged: (v) => toggle(all, v ?? false)),
            Text(t.selectAll),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () async {
                      if (!await confirm(context, message: t.focusDeleteSelected(_selected.length))) return;
                      final repo = ref.read(repositoryProvider);
                      for (final id in [..._selected]) {
                        await repo.deleteFocusRecord(id);
                      }
                      setState(_selected.clear);
                    },
              child: Text('${t.actionDelete} (${_selected.length})'),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ timer detail

/// Detail of a saved timer: Dias focados · Foco de hoje · Foco Total, the week's bars
/// with the daily average, and its records.
Future<void> showTimerDetail(BuildContext context, FocusTimer timer) => showDialog<void>(
  context: context,
  builder: (_) => _TimerDetail(timer: timer),
);

class _TimerDetail extends ConsumerStatefulWidget {
  const _TimerDetail({required this.timer});

  final FocusTimer timer;

  @override
  ConsumerState<_TimerDetail> createState() => _TimerDetailState();
}

class _TimerDetailState extends ConsumerState<_TimerDetail> {
  /// Weeks back from this one ("‹ Esta semana ›").
  int _weeksBack = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final dates = DateLabels(t);
    final timer = widget.timer;
    final today = startOfDay(ref.watch(clockProvider).now());
    final records = [
      for (final r in ref.watch(focusRecordsProvider).value ?? const <FocusRecord>[])
        if (r.deletedAt == null && r.timerId == timer.id) r,
    ];
    int secondsOn(DateTime day) => records.where((r) => startOfDay(r.startedAt.toLocal()) == day).fold(0, (sum, r) => sum + r.seconds);
    final focusedDays = {for (final r in records) startOfDay(r.startedAt.toLocal())}.length;
    final total = records.fold(0, (sum, r) => sum + r.seconds);
    final weekStart = startOfWeek(today).subtract(Duration(days: 7 * _weeksBack));
    final week = [for (var i = 0; i < 7; i++) DateTime(weekStart.year, weekStart.month, weekStart.day + i)];
    final minutes = [for (final d in week) secondsOn(d) / 60];
    final average = minutes.fold(0.0, (a, b) => a + b) / 7;
    Widget card(String label, String value) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tt.text),
            ),
          ],
        ),
      ),
    );
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timer.name, style: const TextStyle(fontSize: 16)),
                Text(
                  timer.mode == FocusMode.pomo ? '${t.focusTabPomo} ${t.focusMinutesValue(timer.minutes)}' : t.focusTabStopwatch,
                  style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 460,
        child: ListView(
          children: [
            Row(
              children: [
                card(t.timerFocusedDays, '$focusedDays'),
                card(t.focusTodayDuration, _time(t, secondsOn(today))),
                card(t.timerTotal, _time(t, total)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.timerDailyAverage(_time(t, (average * 60).round())),
                    style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_left, size: 18), onPressed: () => setState(() => _weeksBack++)),
                Text(
                  _weeksBack == 0
                      ? t.filterDateThisWeek
                      : '${week.first.day} ${dates.monthShort(week.first)} - ${week.last.day} ${dates.monthShort(week.last)}',
                  style: TextStyle(fontSize: TtText.small, color: tt.text),
                ),
                IconButton(icon: const Icon(Icons.chevron_right, size: 18), onPressed: _weeksBack == 0 ? null : () => setState(() => _weeksBack--)),
              ],
            ),
            BarChart(
              values: minutes,
              labels: [for (final d in week) dates.weekdayShort(d)],
              highlight: week.contains(today) ? week.indexOf(today) : null,
              format: (v) => v == 0 ? '' : _time(t, (v * 60).round()),
            ),
            const SizedBox(height: 12),
            for (final r in records.take(50))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(r.mode == FocusMode.pomo ? Icons.timer_outlined : Icons.av_timer, size: 18, color: tt.primary),
                title: Text(
                  '${DateLabels.numeric(r.startedAt.toLocal(), withYear: false)} · '
                  '${DateLabels.time(r.startedAt.toLocal())} - ${DateLabels.time(r.endedAt.toLocal())}',
                ),
                trailing: Text(_time(t, r.seconds), style: TextStyle(color: tt.textSecondary)),
                onTap: () => unawaited(showFocusRecordForm(context, editing: r)),
              ),
          ],
        ),
      ),
    );
  }
}
