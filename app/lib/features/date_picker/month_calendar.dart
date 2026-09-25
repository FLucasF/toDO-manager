import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../l10n/app_localizations.dart';

/// Month grid starting on Sunday (TickTick's default) with ‹ ○ › navigation, today in
/// the primary color, selected days filled and dots on [occurrences].
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.today,
    required this.isSelected,
    required this.occurrences,
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onPick,
  });

  final DateTime month;
  final DateTime today;
  final bool Function(DateTime day) isSelected;
  final Set<DateTime> occurrences;
  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final t = AppLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final start = startOfWeek(first);
    final sundayFirst = [
      t.weekInitialSunday,
      t.weekInitialMonday,
      t.weekInitialTuesday,
      t.weekInitialWednesday,
      t.weekInitialThursday,
      t.weekInitialFriday,
      t.weekInitialSaturday,
    ];
    final initials = [for (final wd in weekdayOrder()) sundayFirst[wd % 7]];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
              ),
            ),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.chevron_left, size: 18), onPressed: onPrevious),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: t.pickerToday,
              icon: const Icon(Icons.circle_outlined, size: 10),
              onPressed: onToday,
            ),
            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.chevron_right, size: 18), onPressed: onNext),
          ],
        ),
        Row(
          children: [
            for (final i in initials)
              Expanded(
                child: Center(
                  child: Text(i, style: TextStyle(fontSize: 11, color: tt.textTertiary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = DateTime(start.year, start.month, start.day + week * 7 + d);
                      final selected = isSelected(day);
                      final isToday = daysBetween(day, today) == 0;
                      final inMonth = day.month == month.month;
                      return InkWell(
                        onTap: () => onPick(day),
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (selected)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(color: tt.primary, shape: BoxShape.circle),
                                ),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selected ? Colors.white : (isToday ? tt.primary : (inMonth ? tt.text : tt.textFaint)),
                                  fontWeight: isToday ? FontWeight.w700 : null,
                                ),
                              ),
                              if (!selected && occurrences.contains(day))
                                Positioned(
                                  bottom: 2,
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: tt.primary, shape: BoxShape.circle),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
