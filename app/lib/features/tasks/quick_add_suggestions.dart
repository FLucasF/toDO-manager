import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../core/clock.dart';
import '../../core/ids.dart';
import '../../domain/enums.dart';
import '../../domain/quick_add.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';

/// One entry of the quick-add popup. Choosing it replaces the token with [insert], text
/// that [parseQuickAdd] understands.
class QuickAddSuggestion {
  const QuickAddSuggestion({required this.icon, required this.label, required this.insert, this.color, this.detail});

  final IconData icon;
  final Color? color;
  final String label;

  /// Shown before the label, e.g. the date "25 set" before "Amanhã".
  final String? detail;
  final String insert;
}

/// Suggestions for [token]: priorities for `!`, tags for `#` (plus "Criar Tag"), dates for `*`, lists
/// for `~` and `^`.
List<QuickAddSuggestion> quickAddSuggestions(ActiveToken token, Snapshot s, AppLocalizations t, TtColors tt, DateTime now) {
  final query = foldForSearch(token.query);
  bool matches(String label) => foldForSearch(label).contains(query);
  final labels = Labels(t);
  switch (token.trigger) {
    case '!':
      return [
        for (final (p, code) in [(Priority.high, 'alta'), (Priority.medium, 'média'), (Priority.low, 'baixa'), (Priority.none, 'nenhuma')])
          if (matches(labels.priority(p)) || matches(code))
            QuickAddSuggestion(icon: Icons.flag, color: tt.priorityColor(p), label: labels.priority(p), insert: '!$code '),
      ];
    case '#':
      final tags = s.activeTags.where((tag) => matches(tag.name)).toList();
      final exact = tags.any((tag) => foldForSearch(tag.name) == query);
      final valid = RegExp(r'^[\p{L}\p{N}_/-]+$', unicode: true).hasMatch(token.query);
      return [
        for (final tag in tags.take(8))
          QuickAddSuggestion(icon: Icons.sell_outlined, color: parseHexColor(tag.color), label: tag.name, insert: '#${tag.name} '),
        if (!exact && valid) QuickAddSuggestion(icon: Icons.add, label: t.quickAddCreateTag(token.query), insert: '#${token.query} '),
      ];
    case '*':
      final today = startOfDay(now);
      final dates = DateLabels(t);
      final nextWeek = today.add(const Duration(days: 7));
      final options = [
        (today, t.relativeToday),
        (today.add(const Duration(days: 1)), t.relativeTomorrow),
        (nextWeek, t.quickAddNextWeekday(dates.weekday(nextWeek).toLowerCase())),
        (DateTime(today.year, today.month + 1, today.day), t.pickerNextMonth),
      ];
      String two(int n) => n.toString().padLeft(2, '0');
      return [
        for (final (day, label) in options)
          if (matches(label))
            QuickAddSuggestion(
              icon: Icons.calendar_today_outlined,
              detail: '${day.day} ${dates.monthShort(day)}',
              label: label,
              // dd/mm/yyyy so a date next year is not read as this year.
              insert: '${two(day.day)}/${two(day.month)}/${day.year} ',
            ),
      ];
    case '~' || '^':
      return [
        for (final list in s.activeLists.where((l) => matches(labels.listName(l))).take(8))
          QuickAddSuggestion(
            icon: list.id == inboxListId ? Icons.inbox_outlined : Icons.list,
            color: parseHexColor(list.color),
            label: labels.listName(list),
            insert: '~${labels.listName(list)} ',
          ),
      ];
  }
  return const [];
}

/// The popup under the add field: tap or arrows + Enter to choose.
class QuickAddSuggestionList extends StatelessWidget {
  const QuickAddSuggestionList({super.key, required this.suggestions, required this.highlighted, required this.onSelect});

  final List<QuickAddSuggestion> suggestions;
  final int highlighted;
  final ValueChanged<QuickAddSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tt.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          children: [
            for (final (i, s) in suggestions.indexed)
              InkWell(
                onTap: () => onSelect(s),
                child: Container(
                  height: 34,
                  color: i == highlighted ? tt.selected : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(s.icon, size: 16, color: s.color ?? tt.textSecondary),
                      const SizedBox(width: 10),
                      if (s.detail != null) ...[
                        Text(
                          s.detail!,
                          style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: TtText.body, color: tt.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
