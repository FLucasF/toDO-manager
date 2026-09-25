import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/preferences_repository.dart';
import '../../domain/color_labels.dart';
import '../../domain/snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';

/// What the color menu picked.
sealed class ColorMenuResult {
  const ColorMenuResult();
}

/// A color, or null for "Padrão" (the list's color).
final class ColorPicked extends ColorMenuResult {
  const ColorPicked(this.color);
  final String? color;
}

/// The actions over the colors in the right-click menu.
enum ColorMenuAction { open, complete, reopen, duplicate, delete }

/// One of the [ColorMenuAction]s.
final class ColorMenuActed extends ColorMenuResult {
  const ColorMenuActed(this.action);
  final ColorMenuAction action;
}

/// Google Calendar's event color menu (its right-click menu and the one beside the calendar on the
/// full page): the named labels, ✎ to edit them, the other colors and "Padrão". [current] is the
/// task's own color; [actions] go on top (Abrir, Concluir, Duplicar, Deletar in the right-click menu).
Future<ColorMenuResult?> showColorLabelMenu(
  BuildContext context, {
  required Offset near,
  required String? current,
  List<ColorMenuAction> actions = const [],
}) => showGeneralDialog<ColorMenuResult>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 100),
  pageBuilder: (context, _, _) => CustomSingleChildLayout(
    delegate: NearPoint(near),
    child: _ColorMenu(current: current, actions: actions),
  ),
);

/// Places a popup under-right of [point] ([gap] away), or left / above when it doesn't fit, kept inside
/// the screen; centered without a point.
class NearPoint extends SingleChildLayoutDelegate {
  NearPoint(this.point, {this.gap = 0});

  final Offset? point;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.loose(constraints.biggest).deflate(const EdgeInsets.all(8));

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final child = childSize;
    final point = this.point;
    if (point == null) return Offset((size.width - child.width) / 2, (size.height - child.height) / 2);
    final x = point.dx + gap + child.width + 8 > size.width ? point.dx - gap - child.width : point.dx + gap;
    final y = point.dy + child.height + 8 > size.height ? point.dy - child.height : point.dy;
    return Offset(x.clamp(8, math.max(8, size.width - child.width - 8)), y.clamp(8, math.max(8, size.height - child.height - 8)));
  }

  @override
  bool shouldRelayout(NearPoint old) => old.point != point || old.gap != gap;
}

class _ColorMenu extends ConsumerWidget {
  const _ColorMenu({required this.current, required this.actions});

  final String? current;
  final List<ColorMenuAction> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final labels = (ref.watch(preferencesProvider).value ?? Preferences.defaults).colorLabels;
    final names = t.eventColorNames.split(',');
    final selected = current == null ? null : normalizeColor(current!);
    void pick(ColorMenuResult r) => Navigator.pop(context, r);
    // Colors picked in the palette before (still on some task), to use again.
    final tasks = (ref.watch(snapshotProvider).value ?? Snapshot.empty()).tasks;
    final custom = {
      for (final c in [?selected, for (final task in tasks) ?task.color])
        if (!eventPalette.contains(normalizeColor(c)) && labelOf(c, labels) == null) normalizeColor(c),
    }.take(12);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tt.divider),
      ),
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (actions.isNotEmpty) ...[
                for (final a in actions)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => pick(ColorMenuActed(a)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            switch (a) {
                              ColorMenuAction.open => Icons.open_in_new,
                              ColorMenuAction.complete => Icons.check_circle_outline,
                              ColorMenuAction.reopen => Icons.replay,
                              ColorMenuAction.duplicate => Icons.copy_outlined,
                              ColorMenuAction.delete => Icons.delete_outline,
                            },
                            size: 20,
                            color: tt.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              switch (a) {
                                ColorMenuAction.open => t.calendarOpen,
                                ColorMenuAction.complete => t.calendarMarkDone,
                                ColorMenuAction.reopen => t.calendarMarkUndone,
                                ColorMenuAction.duplicate => t.menuDuplicate,
                                ColorMenuAction.delete => t.actionDelete,
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: tt.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Divider(height: 12, color: tt.divider),
              ],
              // The labels, then ✎ to edit them.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final l in labels)
                    Tooltip(
                      message: l.name,
                      waitDuration: const Duration(milliseconds: 600),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => pick(ColorPicked(l.color)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                          decoration: BoxDecoration(
                            color: l.color == selected ? parseHexColor(l.color)!.withValues(alpha: 0.18) : null,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: l.color == selected ? parseHexColor(l.color)! : tt.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Dot(color: parseHexColor(l.color)!, size: 16),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 200),
                                child: Text(
                                  l.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: TtText.body, color: tt.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Tooltip(
                    message: t.colorLabelsEdit,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => unawaited(showColorLabelsEditor(context)),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: tt.divider),
                        ),
                        child: Icon(Icons.edit_outlined, size: 16, color: tt.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // The colors without a label.
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final (i, color) in eventPalette.indexed)
                    if (labelOf(color, labels) == null)
                      Tooltip(
                        message: i < names.length ? names[i] : color,
                        waitDuration: const Duration(milliseconds: 600),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => pick(ColorPicked(color)),
                          child: _Dot(color: parseHexColor(color)!, size: 20, checked: color == selected),
                        ),
                      ),
                  for (final color in custom)
                    Tooltip(
                      message: t.colorCustom,
                      waitDuration: const Duration(milliseconds: 600),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => pick(ColorPicked(color)),
                        child: _Dot(color: parseHexColor(color)!, size: 20, checked: color == selected),
                      ),
                    ),
                  // Any other color, in the palette.
                  Tooltip(
                    message: t.colorCustom,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final hex = await showColorPicker(context, initial: current);
                        if (hex != null && context.mounted) pick(ColorPicked(hex));
                      },
                      child: const _Rainbow(size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // "Padrão": the list's color.
              Material(
                color: tt.fieldFill,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => pick(const ColorPicked(null)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selected == null) ...[Icon(Icons.check_circle, size: 18, color: tt.primary), const SizedBox(width: 8)],
                        Text(
                          t.colorDefault,
                          style: TextStyle(fontWeight: FontWeight.w600, color: tt.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rainbow with "+": opens the palette for any color.
class _Rainbow extends StatelessWidget {
  const _Rainbow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red]),
    ),
    child: Icon(Icons.add, size: size * 0.7, color: Colors.white),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, this.checked = false});

  final Color color;
  final double size;
  final bool checked;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: checked ? Icon(Icons.check, size: size * 0.7, color: Colors.white) : null,
  );
}

/// "Editar rótulos": name the colors. A label whose color changes takes its tasks along; a deleted
/// label leaves its tasks with the color, unnamed.
Future<void> showColorLabelsEditor(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _LabelsEditor());

class _LabelsEditor extends ConsumerStatefulWidget {
  const _LabelsEditor();

  @override
  ConsumerState<_LabelsEditor> createState() => _LabelsEditorState();
}

class _LabelRow {
  _LabelRow({required this.original, required this.color, required String name}) : name = TextEditingController(text: name);

  /// The color it had when the editor opened (null = new).
  final String? original;
  String color;
  final TextEditingController name;
}

class _LabelsEditorState extends ConsumerState<_LabelsEditor> {
  late final List<_LabelRow> _rows = [
    for (final l in (ref.read(preferencesProvider).value ?? Preferences.defaults).colorLabels)
      _LabelRow(original: l.color, color: l.color, name: l.name),
  ];

  /// Removed rows; their fields are disposed with the dialog (they may still be on screen this frame).
  final _removed = <_LabelRow>[];

  @override
  void dispose() {
    for (final r in [..._rows, ..._removed]) {
      r.name.dispose();
    }
    super.dispose();
  }

  Set<String> get _used => {for (final r in _rows) r.color};

  void _add() {
    final free = eventPalette.where((c) => !_used.contains(c)).firstOrNull;
    if (free == null) return;
    setState(() => _rows.add(_LabelRow(original: null, color: free, name: '')));
  }

  Future<void> _save() async {
    final kept = [
      for (final r in _rows)
        if (r.name.text.trim().isNotEmpty) r,
    ];
    final repo = ref.read(repositoryProvider);
    // Two steps, so labels that swap colors don't merge their tasks.
    final moved = [
      for (final r in kept)
        if (r.original != null && r.original != r.color) r,
    ];
    for (final (i, r) in moved.indexed) {
      await repo.recolorTasks(r.original!, '~$i');
    }
    for (final (i, r) in moved.indexed) {
      await repo.recolorTasks('~$i', r.color);
    }
    await ref.read(preferencesRepositoryProvider).setColorLabels([for (final r in kept) ColorLabel(color: r.color, name: r.name.text.trim())]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final names = t.eventColorNames.split(',');
    return AlertDialog(
      title: Text(t.colorLabelsEdit),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.colorLabelsHint,
              style: TextStyle(fontSize: TtText.small, color: tt.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final r in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: t.colorLabelsColor,
                      onSelected: (c) => setState(() => r.color = c),
                      itemBuilder: (menuContext) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: SizedBox(
                            width: 200,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final (i, c) in eventPalette.indexed)
                                  if (c == r.color || !_used.contains(c))
                                    Tooltip(
                                      message: i < names.length ? names[i] : c,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => Navigator.pop(menuContext, c),
                                        child: _Dot(color: parseHexColor(c)!, size: 22, checked: c == r.color),
                                      ),
                                    ),
                                if (!eventPalette.contains(r.color)) _Dot(color: parseHexColor(r.color)!, size: 22, checked: true),
                                // Any other color, in the palette.
                                Tooltip(
                                  message: t.colorCustom,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () async {
                                      Navigator.pop(menuContext);
                                      final hex = await showColorPicker(context, initial: r.color);
                                      if (hex != null && mounted && !_used.contains(hex)) setState(() => r.color = hex);
                                    },
                                    child: const _Rainbow(size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: _Dot(color: parseHexColor(r.color)!, size: 22),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: r.name,
                        autofocus: r.original == null,
                        decoration: InputDecoration(hintText: t.colorLabelsName, isDense: true),
                      ),
                    ),
                    IconButton(
                      tooltip: t.actionDelete,
                      icon: Icon(Icons.close, size: 18, color: tt.textSecondary),
                      onPressed: () => setState(() {
                        _rows.remove(r);
                        _removed.add(r);
                      }),
                    ),
                  ],
                ),
              ),
            if (_used.length < eventPalette.length)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 18), label: Text(t.colorLabelsAdd)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionCancel)),
        FilledButton(onPressed: () => unawaited(_save()), child: Text(t.actionSave)),
      ],
    );
  }
}
