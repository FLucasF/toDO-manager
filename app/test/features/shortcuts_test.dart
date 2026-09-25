import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';

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

  Future<void> pumpApp(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(clock)],
        child: TasksApp(initialLocation: location),
      ),
    );
    await settle(tester);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('N opens quick add; / searches and Enter opens the result; G→I goes to the Inbox', (tester) async {
    final repo = Repository(db, clock: clock);
    await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Pagar o aluguel'));
    await pumpApp(tester, '/q/today/tasks');

    // N opens the global quick add; in Hoje the task gets today's date.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Adicionar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Ligar para a escola !alta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text('Adicionar'), findsNothing, reason: 'Enter adds and closes');
    final created = (await tester.runAsync(() => db.select(db.tasks).get()))!.singleWhere((t) => t.title == 'Ligar para a escola');
    expect(created.priority, Priority.high);
    expect(created.dueDate!.toLocal(), DateTime(2026, 9, 24));

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).last, 'aluguel');
    await tester.pump();
    expect(find.text('Pagar o '), findsNothing);
    expect(find.textContaining('aluguel', findRichText: true), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.text('Pagar o aluguel'), findsWidgets, reason: 'the task opens in the detail');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await settle(tester);
    expect(find.text('Caixa de Entrada'), findsWidgets);
    await dispose(tester);
  });

  testWidgets('Tab+M completes the open task; Alt+3 sets high priority; Ctrl+K opens the palette', (tester) async {
    final repo = Repository(db, clock: clock);
    final id = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Revisar contrato'));
    await pumpApp(tester, '/p/inbox/tasks/$id');
    // Leaving any field sends the focus back to the shortcuts.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(tester);
    expect((await tester.runAsync(() => repo.task(id!)))!.priority, Priority.high);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    await settle(tester);
    expect((await tester.runAsync(() => repo.task(id!)))!.status, TaskStatus.completed);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Nova tarefa'), findsOneWidget);
    expect(find.text('G→T'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await dispose(tester);
  });

  testWidgets('Ctrl+click selects several tasks; the batch panel sets the priority of all; Esc clears', (tester) async {
    final repo = Repository(db, clock: clock);
    final a = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Tarefa A'));
    final b = await tester.runAsync(() => repo.createTask(listId: inboxListId, title: 'Tarefa B'));
    await pumpApp(tester, '/p/inbox/tasks');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(find.text('Tarefa A'));
    await tester.tap(find.text('Tarefa B'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    expect(find.text('Você escolheu 2 itens'), findsOneWidget);

    await tester.tap(find.text('Prioridade'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Alta').last);
    await settle(tester);
    for (final id in [a!, b!]) {
      expect((await tester.runAsync(() => repo.task(id)))!.priority, Priority.high);
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.text('Você escolheu 2 itens'), findsNothing);
    await dispose(tester);
  });

  testWidgets('Kanban: V→K shows section columns; a card dragged to a column changes section; + adds in the column', (tester) async {
    final repo = Repository(db, clock: clock);
    final list = await tester.runAsync(() => repo.createList(name: 'Projeto'));
    final section = await tester.runAsync(() => repo.createSection(list!, 'Em andamento'));
    final task = await tester.runAsync(() => repo.createTask(listId: list!, title: 'Escrever testes'));
    await pumpApp(tester, '/p/$list/tasks');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await settle(tester);
    expect(find.text('Não Classificado'), findsOneWidget);
    expect(find.text('Em andamento'), findsOneWidget);

    final start = tester.getCenter(find.text('Escrever testes'));
    final target = tester.getCenter(find.text('Em andamento')) + const Offset(0, 120);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, target, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);
    expect((await tester.runAsync(() => repo.task(task!)))!.sectionId, section);

    // "+" of the section column opens a field at its top.
    await tester.tap(find.byTooltip('Adicionar tarefa').last);
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Revisar PR');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    final created = (await tester.runAsync(() => db.select(db.tasks).get()))!.singleWhere((t) => t.title == 'Revisar PR');
    expect(created.sectionId, section);
    await dispose(tester);
  });
}
