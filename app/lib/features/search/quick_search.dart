import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/enums.dart';
import '../../domain/quick_add.dart' show foldForSearch;
import '../../domain/search.dart';
import '../../domain/snapshot.dart';
import '../../domain/views.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';
import '../common/labels.dart';

/// Quick search ("/"): a popup with the field, chips Tarefa · Tag · Lista, results with
/// the term highlighted and the list name, and a link to the full search page.
Future<void> showQuickSearch(BuildContext context, {String initialQuery = ''}) async {
  final route = await showDialog<String>(
    context: context,
    builder: (_) => _QuickSearch(initialQuery: initialQuery),
  );
  if (route != null && context.mounted) GoRouter.of(context).go(route);
}

enum _Tab { task, tag, list }

class _Result {
  const _Result({required this.route, required this.child});

  final String route;
  final Widget child;
}

class _QuickSearch extends ConsumerStatefulWidget {
  const _QuickSearch({required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<_QuickSearch> createState() => _QuickSearchState();
}

class _QuickSearchState extends ConsumerState<_QuickSearch> {
  late final _query = TextEditingController(text: widget.initialQuery);
  late final _focus = FocusNode(onKeyEvent: _onKey);
  _Tab _tab = _Tab.task;
  int _highlighted = 0;
  List<_Result> _results = const [];

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _results.isEmpty) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlighted = (_highlighted + (key == LogicalKeyboardKey.arrowDown ? 1 : -1)) % _results.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      Navigator.pop(context, _results[_highlighted].route);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<_Result> _build(AppLocalizations t, TtColors tt, Snapshot s) {
    final labels = Labels(t);
    final query = _query.text.trim();
    final folded = foldForSearch(query);
    switch (_tab) {
      case _Tab.task:
        return [
          for (final hit in searchTasks(s, query, filters: const SearchFilters(statuses: {TaskStatus.open, TaskStatus.completed})).take(30))
            _Result(
              route: Routes.of(ListScope(hit.task.listId), taskId: hit.task.id),
              child: _TaskHit(hit: hit, listName: s.listById[hit.task.listId] == null ? '' : labels.listName(s.listById[hit.task.listId]!)),
            ),
        ];
      case _Tab.tag:
        return [
          for (final tag in s.activeTags.where((tag) => foldForSearch(tag.name).contains(folded)))
            _Result(
              route: Routes.of(TagScope(tag.id)),
              child: _SimpleHit(icon: Icons.sell_outlined, color: parseHexColor(tag.color), label: tag.name),
            ),
        ];
      case _Tab.list:
        return [
          for (final list in s.activeLists.where((l) => foldForSearch(labels.listName(l)).contains(folded)))
            _Result(
              route: Routes.of(ListScope(list.id)),
              child: _SimpleHit(icon: Icons.list, color: parseHexColor(list.color), label: labels.listName(list)),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final s = ref.watch(snapshotProvider).value ?? Snapshot.empty();
    _results = _build(t, tt, s);
    if (_highlighted >= _results.length) _highlighted = 0;

    Widget chip(_Tab tab, String label) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: _tab == tab,
        showCheckmark: false,
        selectedColor: tt.primary,
        labelStyle: TextStyle(color: _tab == tab ? Colors.white : tt.textSecondary),
        onSelected: (_) => setState(() {
          _tab = tab;
          _highlighted = 0;
          _focus.requestFocus();
        }),
      ),
    );

    return Dialog(
      alignment: const Alignment(0, -0.6),
      child: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _query,
                focusNode: _focus,
                autofocus: true,
                style: TextStyle(color: tt.text, fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: t.searchHint,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() => _highlighted = 0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(children: [chip(_Tab.task, t.searchTabTask), chip(_Tab.tag, t.searchTabTag), chip(_Tab.list, t.searchTabList)]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(t.searchNoResults, style: TextStyle(color: tt.textTertiary)),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        for (final (i, r) in _results.indexed)
                          InkWell(
                            onTap: () => Navigator.pop(context, r.route),
                            child: Container(color: i == _highlighted ? tt.selected : null, child: r.child),
                          ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(
                children: [
                  Text(
                    '${t.searchNotFound} ',
                    style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context, Uri(path: Routes.search, queryParameters: {'q': _query.text.trim()}).toString()),
                    child: Text(
                      t.searchFullPage,
                      style: TextStyle(fontSize: TtText.small, color: tt.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleHit extends StatelessWidget {
  const _SimpleHit({required this.icon, required this.label, this.color});

  final IconData icon;
  final Color? color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color ?? tt.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: tt.text)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A task result: title and, when the term is elsewhere, the snippet, with the match highlighted.
class _TaskHit extends StatelessWidget {
  const _TaskHit({required this.hit, required this.listName});

  final SearchHit hit;
  final String listName;

  @override
  Widget build(BuildContext context) {
    final tt = context.tt;
    final task = hit.task;
    final done = task.status != TaskStatus.open;
    TextSpan highlighted(String text, TextStyle style, {bool mark = true}) {
      if (!mark || hit.matchLength == 0) return TextSpan(text: text, style: style);
      final end = hit.matchStart + hit.matchLength;
      return TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, hit.matchStart)),
          TextSpan(
            text: text.substring(hit.matchStart, end),
            style: TextStyle(color: tt.primary, fontWeight: FontWeight.w600),
          ),
          TextSpan(text: text.substring(end)),
        ],
      );
    }

    final titleStyle = TextStyle(
      color: done ? tt.textTertiary : tt.text,
      fontSize: TtText.body,
      decoration: done ? TextDecoration.lineThrough : null,
    );
    final title = hit.field == SearchField.title ? highlighted(task.title, titleStyle) : TextSpan(text: task.title, style: titleStyle);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              switch (task.kind) {
                TaskKind.note => Icons.description_outlined,
                TaskKind.checklist => Icons.checklist,
                TaskKind.text => done ? Icons.check_box_outlined : Icons.check_box_outline_blank,
              },
              size: 16,
              color: tt.priorityColor(task.priority),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (hit.field != SearchField.title && hit.snippet.isNotEmpty)
                  Text.rich(
                    highlighted(hit.snippet, TextStyle(color: tt.textTertiary, fontSize: TtText.small)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            listName,
            style: TextStyle(fontSize: TtText.small, color: tt.textTertiary),
          ),
        ],
      ),
    );
  }
}
