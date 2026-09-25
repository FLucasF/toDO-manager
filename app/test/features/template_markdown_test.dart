import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/features/editor/markdown_codec.dart';
import 'package:task_manager/features/templates/templates.dart';

void main() {
  test('"/ Adicionar a partir do modelo": the content, then the items as checkboxes', () {
    final at = DateTime.utc(2026, 9, 25);
    final template = TaskTemplate(
      id: 't',
      createdAt: at,
      updatedAt: at,
      name: 'Reunião',
      title: 'Reunião',
      content: '## Pauta',
      kind: TaskKind.checklist,
      items: 'Abrir\n\nFechar',
      tagIds: '',
      sortOrder: 0,
    );
    final markdown = templateAsMarkdown(template);
    expect(markdown, '## Pauta\n\n- [ ] Abrir\n- [ ] Fechar');
    final nodes = markdownToEditorDocument(markdown).root.children;
    expect([for (final n in nodes) n.type], ['heading', 'todo_list', 'todo_list']);
  });

  test('(i) of a note: words and characters without the markdown marks', () {
    expect(noteStats(''), (words: 0, characters: 0));
    expect(noteStats('## Pauta\n\n- **Abrir** a reunião'), (words: 4, characters: 20));
  });
}
