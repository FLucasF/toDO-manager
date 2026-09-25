import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;

/// Conversion between the markdown TickTick stores as task content and the
/// editor document.
///
/// Differences from appflowy_editor's default markdown:
/// - bullets are written as `- ` (appflowy writes `* `);
/// - attachments are `![file](<attachmentId>/<fileName>)` and become their own block, not an image;
/// - no trailing line break.
Document markdownToEditorDocument(String markdown) =>
    markdownToDocument(_escapeAttachmentSpaces(markdown), markdownParsers: const [_AttachmentMarkdownParser()]);

String editorDocumentToMarkdown(Document document) =>
    documentToMarkdown(document, customParsers: const [_AttachmentNodeParser(), _BulletNodeParser()]).replaceFirst(RegExp(r'\n+$'), '');

/// File names may contain spaces, which markdown image syntax doesn't allow in the URL. Encode them
/// only inside `![file](...)`; the parser decodes them back.
String _escapeAttachmentSpaces(String markdown) =>
    markdown.replaceAllMapped(RegExp(r'^!\[file\]\((.+)\)$', multiLine: true), (m) => '![file](${m.group(1)!.replaceAll(' ', '%20')})');

/// Attachment block in the editor document.
abstract final class AttachmentBlockKeys {
  static const type = 'attachment';

  /// `<attachmentId>/<fileName>`, as in TickTick's markdown.
  static const reference = 'reference';
}

Node attachmentNode(String reference) => Node(type: AttachmentBlockKeys.type, attributes: {AttachmentBlockKeys.reference: reference});

/// Reads an attachment block's reference. appflowy attributes are `Map<String, dynamic>`, so the type
/// is checked here, at the boundary.
String attachmentReference(Node node) {
  final value = node.attributes[AttachmentBlockKeys.reference];
  if (value is! String || !value.contains('/')) {
    throw FormatException('attachment block without a valid reference: $value');
  }
  return value;
}

class _AttachmentMarkdownParser extends CustomMarkdownParser {
  const _AttachmentMarkdownParser();

  @override
  List<Node> transform(
    md.Node element,
    List<CustomMarkdownParser> parsers, {
    MarkdownListType listType = MarkdownListType.unknown,
    int? startNumber,
  }) {
    // `![file](a/b.txt)` alone on a line arrives as <p><img alt="file" src="a/b.txt"></p>.
    if (element is! md.Element || element.tag != 'p') return const [];
    final children = element.children;
    if (children == null || children.length != 1) return const [];
    final img = children.single;
    if (img is! md.Element || img.tag != 'img' || img.attributes['alt'] != 'file') return const [];
    final src = img.attributes['src'];
    if (src == null || !src.contains('/')) return const [];
    return [attachmentNode(Uri.decodeFull(src))];
  }
}

class _AttachmentNodeParser extends NodeParser {
  const _AttachmentNodeParser();

  @override
  String get id => AttachmentBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) => '![file](${attachmentReference(node)})\n';
}

class _BulletNodeParser extends NodeParser {
  const _BulletNodeParser();

  @override
  String get id => BulletedListBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta ?? (Delta()..insert(''));
    final children = encoder?.convertNodes(node.children, withIndent: true);
    return '- ${DeltaMarkdownEncoder().convert(delta)}\n${children ?? ''}';
  }
}

/// Words and characters of a note's text, without the markdown marks.
({int words, int characters}) noteStats(String markdown) {
  if (markdown.trim().isEmpty) return (words: 0, characters: 0);
  final lines = <String>[];
  void collect(Node node) {
    final text = node.delta?.toPlainText();
    if (text != null && text.isNotEmpty) lines.add(text);
    node.children.forEach(collect);
  }

  collect(markdownToEditorDocument(markdown).root);
  final text = lines.join(' ');
  return (words: RegExp(r'\S+').allMatches(text).length, characters: lines.fold(0, (sum, l) => sum + l.length));
}
