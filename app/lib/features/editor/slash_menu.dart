import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// An item of the content's "/" menu.
class SlashMenuItem {
  const SlashMenuItem(this.name, this.icon, this.apply);

  final String name;
  final IconData icon;
  final Future<void> Function(EditorState editor) apply;
}

/// Formatting items of the "/" menu, in TickTick's order. Items that need app data (Anexo, Subtarefa,
/// Tag, Tarefa vinculada, modelo) are added by the content editor.
List<SlashMenuItem> formattingSlashMenuItems(AppLocalizations t) => [
  SlashMenuItem(t.slashText, Icons.notes, (e) => insertNodeAfterSelection(e, paragraphNode())),
  SlashMenuItem(t.slashHeading1, Icons.title, (e) => insertHeadingAfterSelection(e, 1)),
  SlashMenuItem(t.slashHeading2, Icons.title, (e) => insertHeadingAfterSelection(e, 2)),
  SlashMenuItem(t.slashHeading3, Icons.title, (e) => insertHeadingAfterSelection(e, 3)),
  SlashMenuItem(t.slashBulletedList, Icons.format_list_bulleted, (e) => insertNodeAfterSelection(e, bulletedListNode())),
  SlashMenuItem(t.slashNumberedList, Icons.format_list_numbered, (e) => insertNodeAfterSelection(e, numberedListNode())),
  SlashMenuItem(t.slashChecklistItem, Icons.check_box_outlined, (e) => insertNodeAfterSelection(e, todoListNode(checked: false))),
  SlashMenuItem(t.slashQuote, Icons.format_quote, (e) => insertNodeAfterSelection(e, quoteNode())),
  SlashMenuItem(t.slashDivider, Icons.horizontal_rule, (e) => insertNodeAfterSelection(e, dividerNode())),
];

/// Desktop "/" menu: appflowy's floating menu with TickTick's items and names.
CharacterShortcutEvent desktopSlashMenu(List<SlashMenuItem> items) => customSlashCommand([
  for (final item in items)
    SelectionMenuItem(
      getName: () => item.name,
      icon: (editor, isSelected, style) =>
          Icon(item.icon, size: 18, color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor),
      keywords: [item.name.toLowerCase()],
      handler: (editor, _, _) => item.apply(editor),
    ),
]);

/// Mobile "/" menu. appflowy disables its "/" menu on mobile platforms, so here the slash is inserted
/// and a bottom sheet lists the items; picking one removes the slash and applies the item.
CharacterShortcutEvent mobileSlashMenu(List<SlashMenuItem> items, BuildContext Function() context) => CharacterShortcutEvent(
  key: 'mobile slash menu',
  character: '/',
  handler: (editor) async {
    final selection = editor.selection;
    if (selection == null || !selection.isCollapsed) return false;
    await editor.insertTextAtCurrentSelection('/');
    // The sheet takes focus away from the editor and the selection is lost; keep the position after the slash.
    final afterSlash = editor.selection;

    final currentContext = context();
    if (!currentContext.mounted) return true;
    final picked = await showModalBottomSheet<SlashMenuItem>(
      context: currentContext,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [for (final item in items) ListTile(leading: Icon(item.icon), title: Text(item.name), onTap: () => Navigator.pop(context, item))],
        ),
      ),
    );
    if (picked == null || afterSlash == null) return true;

    final node = editor.getNodeAtPath(afterSlash.start.path);
    if (node == null || afterSlash.start.offset == 0) return true;
    final beforeSlash = Position(path: afterSlash.start.path, offset: afterSlash.start.offset - 1);
    // Remove the slash and give the cursor back to the editor in a single transaction.
    await editor.apply(
      editor.transaction
        ..deleteText(node, beforeSlash.offset, 1)
        ..afterSelection = Selection.collapsed(beforeSlash),
    );
    await picked.apply(editor);
    return true;
  },
);
