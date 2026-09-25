import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/clock.dart';
import '../../domain/enums.dart';
import '../../domain/habits.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';

/// The check-ins of every habit as a spreadsheet ("…" → Exportar). TickTick writes
/// `Habits_AAAAMMDD.xlsx`; this is a CSV with `;` and a BOM, which Excel in Portuguese opens as is.
String habitsCsv(AppLocalizations t, Snapshot s) {
  String cell(Object? v) {
    final text = '${v ?? ''}';
    return text.contains(RegExp('[;"\n]')) ? '"${text.replaceAll('"', '""')}"' : text;
  }

  String two(int n) => n.toString().padLeft(2, '0');
  String amount(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v'.replaceAll('.', ',');
  final rows = <List<Object?>>[
    [
      t.habitExportHabit,
      t.habitExportDate,
      t.habitExportValue,
      t.habitExportGoal,
      t.habitExportUnit,
      t.habitExportStatus,
      t.habitExportMood,
      t.habitExportNote,
    ],
  ];
  for (final h in s.habits.where((h) => h.deletedAt == null)) {
    final checkins = [...s.checkinsOf(h.id)]..sort((a, b) => a.day.compareTo(b.day));
    for (final c in checkins) {
      final day = habitDay(c.day);
      final status = switch (habitDayState(h, c, day)) {
        HabitDayState.done => t.habitExportDone,
        HabitDayState.partial => t.habitExportPartial,
        HabitDayState.skipped => t.habitExportSkipped,
        HabitDayState.failed => t.habitExportFailed,
        _ => '',
      };
      rows.add([
        h.name,
        '${two(day.day)}/${two(day.month)}/${day.year}',
        amount(c.value),
        h.goal == HabitGoal.amount ? amount(h.goalAmount) : '1',
        h.unit,
        status,
        c.mood,
        c.note,
      ]);
    }
  }
  return rows.map((r) => r.map(cell).join(';')).join('\r\n');
}

/// Saves the CSV where the user picks, named `Habits_AAAAMMDD.csv`.
Future<void> exportHabits(BuildContext context, WidgetRef ref) async {
  final t = AppLocalizations.of(context);
  final s = ref.read(snapshotProvider).value ?? Snapshot.empty();
  final now = ref.read(clockProvider).now();
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(habitsCsv(t, s))]);
  final day = startOfDay(now);
  final name = 'Habits_${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}.csv';
  final path = await FilePicker.platform.saveFile(fileName: name, bytes: bytes, type: FileType.custom, allowedExtensions: ['csv']);
  // Desktop returns the chosen path; write it when the picker did not.
  if (path != null && !File(path).existsSync()) await File(path).writeAsBytes(bytes);
  if (path != null && context.mounted) showToast(context, t.habitExported);
}
