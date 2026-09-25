import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/features/countdown/countdown_card.dart';
import 'package:task_manager/features/countdown/countdown_icons.dart';
import 'package:task_manager/l10n/app_localizations.dart';

void main() {
  testWidgets('countdown "Ícone": a tab per category, and a tap picks the icon', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
        home: Builder(
          builder: (context) => TextButton(onPressed: () async => picked = await showCountdownIconPicker(context), child: const Text('abrir')),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    for (final label in ['Evento', 'Pessoa', 'Festas', 'Esporte', 'Animal']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Festas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🎂'));
    await tester.pumpAndSettle();
    expect(picked, '🎂');
    expect(countdownIconSets.values.every((icons) => icons.toSet().length == icons.length), isTrue, reason: 'no repeats inside a category');
  });

  testWidgets('"Texto": one capital letter on the chosen background color', (tester) async {
    (String?, String?)? picked;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(dark: true),
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Scaffold(
            body: CountdownLookFields(icon: null, image: null, onIcon: (icon, color) => picked = (icon, color), onImage: (_) {}),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Texto'));
    await tester.pumpAndSettle();
    expect(find.text('Cor de fundo'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(picked, ('A', '#4CA1FF'));
  });
}
