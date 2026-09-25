import 'package:appflowy_editor/appflowy_editor.dart';
// The task content is markdown: every case must come back identical after
// markdown → editor document → markdown.
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/editor/markdown_codec.dart';

String roundTrip(String markdown) => editorDocumentToMarkdown(markdownToEditorDocument(markdown));

void main() {
  const cases = <String, String>{
    'heading 1': '# Titulo H1',
    'heading 2': '## Titulo H2',
    'heading 3': '### Titulo H3',
    'bullet': '- item de lista',
    'quote': '> uma citacao',
    'numbered': '1. numerado',
    'open checkbox': '- [ ] tarefa no texto',
    'checked checkbox': '- [x] feito',
    'bold': '**negrito**',
    'italic': '_italico_',
    'strikethrough': '~~tachado~~',
    'inline code': '`codigo`',
    'link': '[TickTick](https://ticktick.com)',
    'divider': '---',
    'attachment': '![file](6ab5a778d973b60577cc460f/teste_anexo.txt)',
    'attachment with a space in the name': '![file](abc/nota fiscal.pdf)',
  };

  for (final c in cases.entries) {
    test('round trip: ${c.key}', () => expect(roundTrip(c.value), c.value));
  }

  test('real content stored by TickTick', () {
    const real =
        '![file](6ab5a778d973b60577cc460f/teste_anexo.txt)\n'
        '# Titulo H1\n- item de lista\n> uma citacao\n1. numerado\n- [ ] tarefa no texto **negrito**';
    expect(roundTrip(real), real);
  });

  test('an attachment becomes its own block, not an image', () {
    final doc = markdownToEditorDocument('![file](abc/nota fiscal.pdf)');
    expect(doc.root.children.single.type, AttachmentBlockKeys.type);
    expect(attachmentReference(doc.root.children.single), 'abc/nota fiscal.pdf');
  });

  test('a regular image stays an image', () {
    expect(markdownToEditorDocument('![](https://exemplo.com/a.png)').root.children.single.type, 'image');
  });

  test('task links keep their task: href both ways', () {
    const md = 'Ver [Reunião de planejamento](task:0199a7c2) antes';
    final doc = markdownToEditorDocument(md);
    final delta = doc.root.children.first.delta!;
    final link = delta.whereType<TextInsert>().firstWhere((op) => op.attributes?[AppFlowyRichTextKeys.href] != null);
    expect(link.text, 'Reunião de planejamento');
    expect(link.attributes![AppFlowyRichTextKeys.href], 'task:0199a7c2');
    expect(editorDocumentToMarkdown(doc), md);
  });
}
