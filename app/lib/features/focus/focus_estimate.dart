import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/focus_controller.dart' show focusDuration;
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../domain/summary.dart';
import '../../l10n/app_localizations.dart';
import 'focus_page.dart' show focusRecordsProvider;

/// Pomos and focused time of every task.
final taskFocusProvider = Provider<Map<String, TaskFocus>>((ref) => focusByTask(ref.watch(focusRecordsProvider).value ?? const []));

/// "🍅 1/3" or "⏱ 20m/50m": what was focused against the "Estimativa"; without one, the focused time
/// alone ("⏱ 25m"); null when there is neither.
String? focusEstimateLabel(AppLocalizations t, Task task, TaskFocus? done) {
  String time(int seconds) => focusDuration(
    Duration(seconds: seconds),
    hours: t.focusHours,
    minutes: t.focusMins,
  );
  final pomos = task.estimatedPomos;
  final minutes = task.estimatedMinutes;
  if (pomos != null) return '🍅 ${done?.pomos ?? 0}/$pomos';
  if (minutes != null) return '⏱ ${time(done?.seconds ?? 0)}/${time(minutes * 60)}';
  if (done == null || done.seconds == 0) return null;
  return '⏱ ${time(done.seconds)}';
}

/// "Começar o foco › Estimativa": Pomo Estimado (N Pomos) or Duração estimada (h + min).
Future<void> showEstimateDialog(BuildContext context, WidgetRef ref, Task task) async {
  final picked = await showDialog<({int? pomos, int? minutes})>(
    context: context,
    builder: (_) => _EstimateDialog(task: task),
  );
  if (picked != null) await ref.read(repositoryProvider).setEstimate(task.id, pomos: picked.pomos, minutes: picked.minutes);
}

class _EstimateDialog extends StatefulWidget {
  const _EstimateDialog({required this.task});

  final Task task;

  @override
  State<_EstimateDialog> createState() => _EstimateDialogState();
}

class _EstimateDialogState extends State<_EstimateDialog> {
  late bool _byTime = widget.task.estimatedMinutes != null;
  late int _pomos = widget.task.estimatedPomos ?? 1;
  late int _minutes = widget.task.estimatedMinutes ?? 30;

  Widget _stepper(String value, {required VoidCallback? less, required VoidCallback? more}) {
    final tt = context.tt;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: less, icon: const Icon(Icons.remove)),
        SizedBox(
          width: 110,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, color: tt.text),
          ),
        ),
        IconButton(onPressed: more, icon: const Icon(Icons.add)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final time = focusDuration(
      Duration(minutes: _minutes),
      hours: t.focusHours,
      minutes: t.focusMins,
    );
    return AlertDialog(
      scrollable: true,
      title: Text(t.focusEstimate, style: const TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(t.estimatePomos)),
                ButtonSegment(value: true, label: Text(t.estimateDuration)),
              ],
              selected: {_byTime},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(textStyle: DefaultTextStyle.of(context).style),
              onSelectionChanged: (v) => setState(() => _byTime = v.first),
            ),
            const SizedBox(height: 16),
            if (_byTime)
              _stepper(
                time,
                less: _minutes > 5 ? () => setState(() => _minutes -= _minutes > 60 ? 15 : 5) : null,
                more: _minutes < 24 * 60 ? () => setState(() => _minutes += _minutes >= 60 ? 15 : 5) : null,
              )
            else
              _stepper(
                t.estimatePomoCount(_pomos),
                less: _pomos > 1 ? () => setState(() => _pomos--) : null,
                more: _pomos < 99 ? () => setState(() => _pomos++) : null,
              ),
          ],
        ),
      ),
      actions: [
        if (widget.task.estimatedPomos != null || widget.task.estimatedMinutes != null)
          TextButton(onPressed: () => Navigator.pop(context, (pomos: null, minutes: null)), child: Text(t.dateClear)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _byTime ? (pomos: null, minutes: _minutes) : (pomos: _pomos, minutes: null)),
          child: Text(t.actionOk),
        ),
      ],
    );
  }
}
