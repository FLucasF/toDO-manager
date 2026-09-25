import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The list's grid: every row starts with a slot as wide as the checkbox (checkbox, chevron or icon)
/// at [left], and every title starts at [title]. Group headers, tasks, habits, countdowns and calendar
/// events all follow it, so their texts line up in one column.
abstract final class ListGrid {
  static const double left = 16;
  static const double slot = TtSizes.checkbox;
  static const double gap = 7;
  static const double title = left + slot + gap;
  static const double right = 30;
}

/// The first column of a row: [child] centered on the checkbox column, even when a little wider.
class ListLeading extends StatelessWidget {
  const ListLeading({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ListGrid.slot,
    child: OverflowBox(maxWidth: 28, maxHeight: 28, child: child),
  );
}

/// A row that is not a task (habit, countdown, calendar event) laid out like a task row: leading slot,
/// title on the grid, trailing text or control, and the divider under the title.
class ListItemRow extends StatelessWidget {
  const ListItemRow({super.key, required this.leading, required this.title, this.trailing, this.onTap});

  final Widget leading;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: TtSizes.rowHeight,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: ListGrid.left, right: ListGrid.right),
              child: Row(
                children: [
                  ListLeading(child: leading),
                  const SizedBox(width: ListGrid.gap),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tt.text, fontSize: TtText.body),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Positioned(
              left: ListGrid.title,
              right: ListGrid.right,
              bottom: 0,
              child: Container(height: 1, color: tt.divider),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section title without a chevron ("Hábito", "Contagem Regressiva"), on the titles' column.
class ListSectionTitle extends StatelessWidget {
  const ListSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: TtSizes.groupHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: ListGrid.title, top: 12),
        child: Text(
          text,
          style: TextStyle(fontSize: TtText.body, fontWeight: FontWeight.w600, color: tt.text),
        ),
      ),
    );
  }
}
