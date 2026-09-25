import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/detail/content_editor.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  testWidgets('the "A" bar formats the selection and turns the line into a list or a heading', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(
          body: ContentEditor(markdown: 'olá mundo', placeholder: '', onChanged: saved.add, showFormatBar: true),
        ),
      ),
    );
    await tester.pump();
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    Future<void> apply(IconData icon) async {
      await tester.tap(find.byIcon(icon));
      await tester.pump(const Duration(milliseconds: 500));
    }

    editor.selection = Selection(
      start: Position(path: [0]),
      end: Position(path: [0], offset: 3),
    );
    await apply(Icons.format_bold);
    expect(saved.last, '**olá** mundo');

    editor.selection = Selection.collapsed(Position(path: [0], offset: 1));
    await apply(Icons.format_list_bulleted);
    expect(saved.last, '- **olá** mundo');

    await apply(Icons.title);
    expect(saved.last, '# **olá** mundo', reason: 'the list becomes Título 1');
    await apply(Icons.title);
    expect(saved.last, '## **olá** mundo');
  });

  // appflowy used to loop forever (and eat memory) when the caret sat in a heading taller than the box.
  testWidgets('"/ Título 1" with the caret in a list of the detail does not hang', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Scaffold(
          body: ListView(
            children: [ContentEditor(markdown: 'olá mundo', placeholder: '', onChanged: (_) {})],
          ),
        ),
      ),
    );
    await tester.pump();
    final editor = tester.widget<AppFlowyEditor>(find.byType(AppFlowyEditor)).editorState;
    editor.selection = Selection.collapsed(Position(path: [0], offset: 3));
    await tester.pump();
    final done = insertHeadingAfterSelection(editor, 1);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await done;
    expect(editor.document.root.children.last.type, HeadingBlockKeys.type);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('new markdown from the parent replaces the document, even before any edit', (tester) async {
    Widget app(String markdown) => MaterialApp(
      theme: buildTheme(dark: true),
      locale: const Locale('pt', 'BR'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: ContentEditor(markdown: markdown, placeholder: '', onChanged: (_) {}),
      ),
    );
    await tester.pumpWidget(app('Relatório vazio'));
    await tester.pump();
    // The Resumo builds its report before the tasks load, then gets the real one.
    await tester.pumpWidget(app('Relatório completo'));
    await tester.pump();
    expect(find.text('Relatório completo', findRichText: true), findsOneWidget);
    expect(find.text('Relatório vazio', findRichText: true), findsNothing);
  });
}
