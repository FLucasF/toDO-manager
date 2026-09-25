import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/features/focus/focus_estimate.dart';
import 'package:task_manager/l10n/app_localizations.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  final t = AppLocalizationsPt();
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
  });
  tearDown(() => db.close());

  test('"Estimativa": Pomos or minutes, never both, against what was focused', () async {
    final id = await repo.createTask(listId: inboxListId, title: 'Relatório');
    expect(focusEstimateLabel(t, await repo.task(id), null), isNull);
    expect(focusEstimateLabel(t, await repo.task(id), (pomos: 1, seconds: 1500)), '⏱ 25m', reason: 'focused, no estimate');

    await repo.setEstimate(id, pomos: 3);
    expect(focusEstimateLabel(t, await repo.task(id), (pomos: 1, seconds: 1500)), '🍅 1/3');

    await repo.setEstimate(id, minutes: 50);
    final byTime = await repo.task(id);
    expect((byTime.estimatedPomos, byTime.estimatedMinutes), (null, 50));
    expect(focusEstimateLabel(t, byTime, null), '⏱ 0m/50m');
    expect(focusEstimateLabel(t, byTime, (pomos: 0, seconds: 20 * 60)), '⏱ 20m/50m');

    await repo.setEstimate(id, pomos: 2, minutes: 30);
    final both = await repo.task(id);
    expect((both.estimatedPomos, both.estimatedMinutes), (2, null));

    await repo.setEstimate(id);
    final cleared = await repo.task(id);
    expect((cleared.estimatedPomos, cleared.estimatedMinutes), (null, null));
  });

  testWidgets('the dialog sets a duration in 5-minute steps', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final id = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Relatório'));
    final task = await tester.runAsync(() => repo.task(id!));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildTheme(dark: true),
          locale: const Locale('pt', 'BR'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
          home: Consumer(
            builder: (context, ref, _) => TextButton(onPressed: () => showEstimateDialog(context, ref, task!), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('1 Pomo'), findsOneWidget);
    await tester.tap(find.text(t.estimateDuration));
    await tester.pumpAndSettle();
    expect(find.text('30m'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('40m'), findsOneWidget);
    await tester.tap(find.text(t.actionOk));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() => repo.task(id!));
    expect(saved!.estimatedMinutes, 40);
  });
}
