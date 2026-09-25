import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'markdown_codec.dart';

/// Attachment card inside the content: file icon, name and size, plus the "…" menu.
/// Selection follows appflowy's pattern for text-less blocks (like the divider): the whole block is
/// selected as one unit.
class AttachmentBlockBuilder extends BlockComponentBuilder {
  AttachmentBlockBuilder({
    super.configuration,
    required this.describeSize,
    this.onOpen,
    this.onDownload,
    this.downloadLabel = '',
    this.deleteLabel = '',
  });

  /// Size text ("86 B") for a `<id>/<name>` reference; provided by the attachments repository.
  final String Function(String reference) describeSize;

  /// Opens the file with the system's app when the card is clicked.
  final void Function(String reference)? onOpen;

  /// "Baixar" of the card's "…" menu: saves a copy where the user chooses.
  final void Function(String reference)? onDownload;
  final String downloadLabel;
  final String deleteLabel;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return _AttachmentBlock(
      key: node.key,
      node: node,
      configuration: configuration,
      describeSize: describeSize,
      onOpen: onOpen,
      onDownload: onDownload,
      downloadLabel: downloadLabel,
      deleteLabel: deleteLabel,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.children.isEmpty;
}

class _AttachmentBlock extends BlockComponentStatefulWidget {
  const _AttachmentBlock({
    super.key,
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
    required this.describeSize,
    this.onOpen,
    this.onDownload,
    this.downloadLabel = '',
    this.deleteLabel = '',
  });

  final String Function(String reference) describeSize;
  final void Function(String reference)? onOpen;
  final void Function(String reference)? onDownload;
  final String downloadLabel;
  final String deleteLabel;

  @override
  State<_AttachmentBlock> createState() => _AttachmentBlockState();
}

class _AttachmentBlockState extends State<_AttachmentBlock> with SelectableMixin, BlockComponentConfigurable {
  final _cardKey = GlobalKey();

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox? get _box => context.findRenderObject() as RenderBox?;

  @override
  Widget build(BuildContext context) {
    final reference = attachmentReference(node);
    final name = reference.substring(reference.indexOf('/') + 1);
    final colors = Theme.of(context).colorScheme;
    final editorState = context.read<EditorState>();

    Widget child = Container(
      key: _cardKey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: colors.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.description, color: colors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis),
                Text(widget.describeSize(reference), style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            icon: Icon(Icons.more_horiz, color: colors.onSurface.withValues(alpha: 0.6)),
            // The card's menu: Baixar · Deletar.
            onSelected: (action) {
              if (action == 'download') {
                widget.onDownload?.call(reference);
              } else {
                final transaction = editorState.transaction..deleteNode(node);
                editorState.apply(transaction);
              }
            },
            itemBuilder: (_) => [
              if (widget.onDownload != null) PopupMenuItem(value: 'download', height: 36, child: Text(widget.downloadLabel)),
              PopupMenuItem(value: 'delete', height: 36, child: Text(widget.deleteLabel)),
            ],
          ),
        ],
      ),
    );
    child = GestureDetector(onTap: widget.onOpen == null ? null : () => widget.onOpen!(reference), child: child);

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      cursorColor: editorState.editorStyle.cursorColor,
      selectionColor: editorState.editorStyle.selectionColor,
      supportTypes: const [BlockSelectionType.block, BlockSelectionType.cursor, BlockSelectionType.selection],
      child: Padding(padding: padding, child: child),
    );
    return Padding(padding: margin, child: child);
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) => getRectsInSelection(Selection.invalid()).first;

  @override
  Rect? getCursorRectInPosition(Position position, {bool shiftWithBaseOffset = false}) {
    if (_box == null) return null;
    return getRectsInSelection(Selection.collapsed(position), shiftWithBaseOffset: shiftWithBaseOffset).firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(Selection selection, {bool shiftWithBaseOffset = false}) {
    final box = _box;
    if (box == null) return [];
    final card = _cardKey.currentContext?.findRenderObject();
    if (card is RenderBox) {
      final origin = shiftWithBaseOffset ? card.localToGlobal(Offset.zero, ancestor: box) : Offset.zero;
      return [origin & card.size];
    }
    return [Offset.zero & box.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) => _box!.localToGlobal(offset);

  @override
  TextDirection textDirection() => TextDirection.ltr;
}
