import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/common/emoji_picker.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  testWidgets('emoji picker: categories, search in Portuguese without accents, Redefinir', (tester) async {
    String? picked = 'none';
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Builder(
          builder: (context) => TextButton(onPressed: () async => picked = await showEmojiPicker(context), child: const Text('abrir')),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoas e Corpo'), findsOneWidget);
    await tester.tap(find.byTooltip('Comida'));
    await tester.pumpAndSettle();
    expect(find.text('🍕'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Café');
    await tester.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    await tester.tap(find.text('☕'));
    await tester.pumpAndSettle();
    expect(picked, '☕');

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redefinir'));
    await tester.pumpAndSettle();
    expect(picked, '');
  });
}
