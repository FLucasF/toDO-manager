import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/domain/task_defaults.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/features/settings/settings_dialog.dart';
import 'package:task_manager/features/tasks/task_list_pane.dart';

void main() {
  late AppDatabase db;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Funcionalidades hides a module; Lista inteligente hides the Inbox; Aparência keeps the color series', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/q/today/tasks'),
      ),
    );
    await settle(tester);
    expect(find.byTooltip('Matriz de Eisenhower'), findsOneWidget);
    expect(find.text('Caixa de Entrada'), findsOneWidget);

    showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.features).ignore();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.widgetWithText(SwitchListTile, 'Matriz de Eisenhower'), matching: find.byType(Switch)));
    await settle(tester);

    await tester.tap(find.text('Lista inteligente'));
    await tester.pumpAndSettle();
    final inboxRow = find.ancestor(of: find.text('Caixa de Entrada').last, matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: inboxRow, matching: find.byType(DropdownButton<SmartListVisibility>)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esconder').last);
    await settle(tester);

    await tester.tap(find.text('Aparência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lilás'));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Matriz de Eisenhower'), findsNothing);
    expect(find.text('Caixa de Entrada'), findsNothing);
    final prefs = (await tester.runAsync(() => PreferencesRepository(db).watch().first))!;
    expect(prefs.disabledFeatures, {AppFeature.matrix});
    expect((prefs.inboxVisibility, prefs.colorSeries), (SmartListVisibility.hide, ColorSeries.lilac));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('task defaults: a task added in Todas goes to the default list with its date, priority and place', (tester) async {
    late String work;
    await tester.runAsync(() async {
      final repo = Repository(db, clock: clock);
      work = await repo.createList(name: 'Trabalho');
      await repo.createTask(listId: work, title: 'antiga');
      await PreferencesRepository(
        db,
        clock: clock,
      ).setTaskDefaults(TaskDefaults(listId: work, date: DefaultDate.tomorrow, priority: Priority.high, addAtTop: false));
    });
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/q/all/tasks'),
      ),
    );
    await settle(tester);
    expect(find.text("Adicionar tarefa a 'Trabalho'"), findsOneWidget);
    await tester.tap(find.text("Adicionar tarefa a 'Trabalho'"));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'nova');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    final tasks = (await tester.runAsync(() => (db.select(db.tasks)..where((t) => t.listId.equals(work))).get()))!;
    final added = tasks.singleWhere((t) => t.title == 'nova');
    expect((added.dueDate?.toLocal(), added.priority), (DateTime(2026, 9, 25), Priority.high));
    // "Fim da lista": after the task that was already there.
    expect(added.sortOrder > tasks.singleWhere((t) => t.title == 'antiga').sortOrder, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('Atalhos: an action gets a new sequence recorded from the keyboard', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/p/inbox/tasks'),
      ),
    );
    await settle(tester);
    showSettings(tester.element(find.byType(TaskListPane)), tab: SettingsTab.shortcuts).ignore();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ir para Hoje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para Hoje'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duas teclas em sequência (ex.: G → T)'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pumpAndSettle();
    expect(find.text('H→J'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await settle(tester);
    final prefs = (await tester.runAsync(() => PreferencesRepository(db).watch().first))!;
    expect(prefs.customShortcuts['goToday'], ['h j']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('Duração padrão: a task typed with a time gets the default length', (tester) async {
    await tester.runAsync(() => PreferencesRepository(db, clock: clock).setTaskDefaults(const TaskDefaults(durationMinutes: 60)));
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: const TasksApp(initialLocation: '/p/inbox/tasks'),
      ),
    );
    await settle(tester);
    await tester.tap(find.textContaining('Adicionar tarefa'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Reunião amanhã 15h');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    final task = (await tester.runAsync(() => (db.select(db.tasks)..where((t) => t.title.equals('Reunião'))).getSingle()))!;
    expect((task.startDate!.toLocal(), task.dueDate!.toLocal()), (DateTime(2026, 9, 25, 15), DateTime(2026, 9, 25, 16)));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  });
}
