import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format/date_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/enums.dart';
import '../../domain/habits.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';

String _number(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

/// The habit's icon: an emoji or a letter on its color.
class HabitIcon extends StatelessWidget {
  const HabitIcon({super.key, required this.habit, this.size = 32});

  final Habit habit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(habit.color) ?? context.tt.primary;
    final text = habit.icon.isNotEmpty ? habit.icon : (habit.name.isEmpty ? '?' : habit.name.characters.first.toUpperCase());
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: Text(
        text,
        style: TextStyle(fontSize: size * 0.5, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// One day of a habit: a click checks in, a right click (long press on phones) opens
/// Registro de hábitos · Pular · Incompleta · Reiniciar hábito.
class HabitDot extends ConsumerWidget {
  const HabitDot({super.key, required this.habit, required this.checkin, required this.day, this.size = 26});

  final Habit habit;
  final HabitCheckin? checkin;
  final DateTime day;
  final double size;

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final state = habitDayState(habit, checkin, day);
    if (state == HabitDayState.notRequired || state == HabitDayState.done) return;
    if (habit.goal == HabitGoal.amount && habit.checkMode == HabitCheckMode.manual) {
      final amount = await _askAmount(context);
      if (amount == null) return;
      await repo.checkIn(habit.id, day, amount: amount);
    } else {
      await repo.checkIn(habit.id, day);
    }
    if (habit.autoShowLog && context.mounted) await showHabitLog(context, ref, habit, day, checkin);
  }

  /// Manual amount: "24 setembro / Aumentar [__] copos".
  Future<double?> _askAmount(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${day.day} ${DateLabels(t).monthLong(day)}', style: const TextStyle(fontSize: 15)),
        content: Row(
          children: [
            Text('${t.habitIncrease} '),
            SizedBox(
              width: 70,
              child: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number),
            ),
            Text(' ${habit.unit}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.habitDetailClose)),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))), child: Text(t.actionOk)),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, Offset at) async {
    final t = AppLocalizations.of(context);
    final repo = ref.read(repositoryProvider);
    final state = habitDayState(habit, checkin, day);
    if (state == HabitDayState.notRequired && checkin == null) return;
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        PopupMenuItem(value: 'log', height: 36, child: Text(t.habitLog)),
        if (state == HabitDayState.open || state == HabitDayState.partial) PopupMenuItem(value: 'skip', height: 36, child: Text(t.habitSkip)),
        if (state != HabitDayState.failed) PopupMenuItem(value: 'fail', height: 36, child: Text(t.habitFail)),
        if (state != HabitDayState.open) PopupMenuItem(value: 'reset', height: 36, child: Text(t.habitReset)),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'log':
        await showHabitLog(context, ref, habit, day, checkin);
      case 'skip':
        await repo.markHabitDay(habit.id, day, HabitMark.skipped);
      case 'fail':
        await repo.markHabitDay(habit.id, day, HabitMark.failed);
      case 'reset':
        await repo.resetHabitDay(habit.id, day);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final state = habitDayState(habit, checkin, day);
    final color = parseHexColor(habit.color) ?? tt.primary;
    final value = checkin?.value ?? 0;
    final child = switch (state) {
      HabitDayState.done => Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(Icons.check, size: size * 0.6, color: Colors.white),
      ),
      HabitDayState.failed => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tt.overdue, width: 1.5),
        ),
        child: Icon(Icons.close, size: size * 0.6, color: tt.overdue),
      ),
      HabitDayState.skipped => Container(
        decoration: BoxDecoration(color: tt.divider, shape: BoxShape.circle),
        child: Icon(Icons.remove, size: size * 0.6, color: tt.textTertiary),
      ),
      HabitDayState.partial => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: (value / habit.goalAmount).clamp(0, 1).toDouble(),
              strokeWidth: 2.5,
              color: color,
              backgroundColor: tt.divider,
            ),
          ),
          Text(
            _number(value),
            style: TextStyle(fontSize: size * 0.34, color: tt.textSecondary),
          ),
        ],
      ),
      HabitDayState.open => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tt.textFaint, width: 1.5),
        ),
      ),
      // Hatched: not needed that day.
      HabitDayState.notRequired => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: tt.divider),
        ),
        child: Icon(Icons.more_horiz, size: size * 0.5, color: tt.divider),
      ),
    };
    return Tooltip(
      message: '${DateLabels(t).weekdayShort(day)}, ${day.day} ${DateLabels(t).monthLong(day)}',
      child: GestureDetector(
        onTap: () => unawaited(_checkIn(context, ref)),
        onSecondaryTapUp: (d) => unawaited(_menu(context, ref, d.globalPosition)),
        onLongPressStart: (d) => unawaited(_menu(context, ref, d.globalPosition)),
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

/// "Registro de hábitos": the day, five moods and the note.
Future<void> showHabitLog(BuildContext context, WidgetRef ref, Habit habit, DateTime day, HabitCheckin? checkin) async {
  final t = AppLocalizations.of(context);
  final note = TextEditingController(text: checkin?.note ?? '');
  var mood = checkin?.mood;
  const moods = ['😞', '🙁', '😐', '🙂', '😄'];
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final tt = context.tt;
        return AlertDialog(
          title: Text(habit.name, style: const TextStyle(fontSize: 15)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  DateLabels(t).detailDate(day, isAllDay: true, today: DateTime.now()),
                  style: TextStyle(color: tt.textTertiary, fontSize: TtText.small),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < moods.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => mood = mood == i + 1 ? null : i + 1),
                        child: Opacity(
                          opacity: mood == null || mood == i + 1 ? 1 : 0.35,
                          child: Text(moods[i], style: const TextStyle(fontSize: 30)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(hintText: t.habitLogPrompt),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.actionSave)),
          ],
        );
      },
    ),
  );
  final text = note.text;
  note.dispose();
  if (ok == true) await ref.read(repositoryProvider).saveHabitLog(habit.id, day, mood: mood, note: text);
}

/// "3/8 copos" of an amount habit on a day.
String habitAmountText(AppLocalizations t, Habit h, HabitCheckin? c) =>
    t.habitAmount(_number(c?.value ?? 0), _number(h.goalAmount), h.unit.isEmpty ? t.habitUnitDefault : h.unit);
