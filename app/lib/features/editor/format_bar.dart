import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../app/format/date_labels.dart';
import '../../app/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../common/feedback.dart';

/// The formatting bar of the content (the "A" of the detail footer): títulos, negrito,
/// itálico, sublinhado, tachado, caixa de seleção, listas, citação, divisor, hora, link and código.
/// Buttons don't take the focus, so the editor keeps its selection.
class FormatBar extends StatelessWidget {
  const FormatBar({super.key, required this.editor, required this.now, this.onImmersive});

  final EditorState editor;

  /// "Escrita Imersiva" (Ctrl+Alt+U): the content full screen.
  final VoidCallback? onImmersive;

  /// The clock for "Tempo" (the date and time inserted).
  final DateTime Function() now;

  Node? get _node {
    final selection = editor.selection;
    return selection == null ? null : editor.getNodeAtPath(selection.start.path);
  }

  /// Turns the current line into [type] (or back into text when it already is one).
  Future<void> _block(String type, [Attributes extra = const {}]) async {
    final selection = editor.selection;
    final node = _node;
    if (selection == null || node == null || node.delta == null) return;
    final same = node.type == type && extra.entries.every((e) => node.attributes[e.key] == e.value);
    await editor.formatNode(
      selection,
      (n) => n.copyWith(type: same ? ParagraphBlockKeys.type : type, attributes: {ParagraphBlockKeys.delta: n.delta!.toJson(), if (!same) ...extra}),
    );
  }

  /// "H": texto → Título 1 → 2 → 3 → texto.
  Future<void> _heading() async {
    final node = _node;
    final level = node?.type == HeadingBlockKeys.type ? node!.attributes[HeadingBlockKeys.level] : null;
    final next = switch (level) {
      1 => 2,
      2 => 3,
      3 => null,
      _ => 1,
    };
    if (next == null) {
      await _block(HeadingBlockKeys.type, {HeadingBlockKeys.level: 3});
    } else {
      final selection = editor.selection;
      if (selection == null || node?.delta == null) return;
      await editor.formatNode(
        selection,
        (n) => n.copyWith(type: HeadingBlockKeys.type, attributes: {HeadingBlockKeys.delta: n.delta!.toJson(), HeadingBlockKeys.level: next}),
      );
    }
  }

  Future<void> _link(BuildContext context, AppLocalizations t) async {
    final selection = editor.selection;
    if (selection == null || selection.isCollapsed) return;
    final url = await promptText(context, title: t.formatLink, hint: 'https://');
    if (url == null || url.trim().isEmpty) return;
    await editor.formatDelta(selection, {AppFlowyRichTextKeys.href: url.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    Widget button(IconData icon, String tooltip, Future<void> Function() onTap) => Tooltip(
      message: tooltip,
      child: InkWell(
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(4),
        onTap: () => onTap(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: tt.textSecondary),
        ),
      ),
    );
    Future<void> toggle(String key) => editor.toggleAttribute(key);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: tt.fieldFill, borderRadius: BorderRadius.circular(6)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            button(Icons.title, t.formatHeading, _heading),
            button(Icons.format_bold, t.formatBold, () => toggle(AppFlowyRichTextKeys.bold)),
            button(Icons.format_italic, t.formatItalic, () => toggle(AppFlowyRichTextKeys.italic)),
            button(Icons.format_underline, t.formatUnderline, () => toggle(AppFlowyRichTextKeys.underline)),
            button(Icons.format_strikethrough, t.formatStrikethrough, () => toggle(AppFlowyRichTextKeys.strikethrough)),
            button(Icons.check_box_outlined, t.slashChecklistItem, () => _block(TodoListBlockKeys.type, {TodoListBlockKeys.checked: false})),
            button(Icons.format_list_bulleted, t.slashBulletedList, () => _block(BulletedListBlockKeys.type)),
            button(Icons.format_list_numbered, t.slashNumberedList, () => _block(NumberedListBlockKeys.type)),
            button(Icons.format_quote, t.slashQuote, () => _block(QuoteBlockKeys.type)),
            button(Icons.horizontal_rule, t.slashDivider, () => insertNodeAfterSelection(editor, dividerNode())),
            // "Tempo": the date and time, where the cursor is.
            button(Icons.schedule, t.formatTime, () async {
              final at = now();
              if (editor.selection == null) return;
              await editor.insertTextAtCurrentSelection('${DateLabels.numeric(at)} ${DateLabels.time(at)}');
            }),
            button(Icons.link, t.formatLink, () => _link(context, t)),
            button(Icons.code, t.formatCode, () => toggle(AppFlowyRichTextKeys.code)),
            if (onImmersive case final open?) button(Icons.fullscreen, t.formatImmersive, () async => open()),
          ],
        ),
      ),
    );
  }
}
