import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/db/database.dart';
import '../../l10n/app_localizations.dart';
import '../common/color_choice.dart';

class TagForm {
  const TagForm({required this.name, required this.color, required this.parentId});

  final String name;
  final String? color;
  final String? parentId;
}

/// "Adicionar Tags" / "Editar tag": name, color and parent tag.
///
/// Editing, [onDelete] shows the bin: it asks and deletes, and the dialog closes when it did.
Future<TagForm?> showTagDialog(BuildContext context, {Tag? editing, String? parentId, Future<bool> Function()? onDelete}) => showDialog<TagForm>(
  context: context,
  builder: (_) => _TagDialog(editing: editing, initialParentId: parentId, onDelete: onDelete),
);

class _TagDialog extends ConsumerStatefulWidget {
  const _TagDialog({this.editing, this.initialParentId, this.onDelete});

  final Tag? editing;
  final String? initialParentId;
  final Future<bool> Function()? onDelete;

  @override
  ConsumerState<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends ConsumerState<_TagDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.editing?.name ?? '');
  late String? _color = widget.editing?.color;
  late String? _parentId = widget.editing?.parentId ?? widget.initialParentId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim().replaceFirst(RegExp('^#'), '');
    if (name.isEmpty) return;
    Navigator.pop(context, TagForm(name: name, color: _color, parentId: _parentId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final tt = context.tt;
    final tags = (ref.watch(snapshotProvider).value?.activeTags ?? const <Tag>[])
        .where((tag) => tag.id != widget.editing?.id && tag.parentId == null)
        .toList();
    return AlertDialog(
      title: Text(widget.editing == null ? t.tagAddTitle : t.tagEditTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: t.tagNameHint,
                filled: true,
                fillColor: tt.fieldFill,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            Text(t.tagColor, style: TextStyle(color: tt.textSecondary)),
            const SizedBox(height: 6),
            ColorChoice(value: _color, onChanged: (c) => setState(() => _color = c)),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(t.tagParent, style: TextStyle(color: tt.textSecondary)),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _parentId,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.tagParentNone)),
                    for (final tag in tags) DropdownMenuItem(value: tag.id, child: Text(tag.name)),
                  ],
                  onChanged: (v) => setState(() => _parentId = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (widget.editing != null && widget.onDelete != null)
          IconButton(
            tooltip: t.actionDelete,
            icon: Icon(Icons.delete_outline, color: context.tt.overdue),
            onPressed: () async {
              if (await widget.onDelete!() && context.mounted) Navigator.pop(context);
            },
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.actionClose)),
        FilledButton(onPressed: _submit, child: Text(t.actionSave)),
      ],
    );
  }
}
