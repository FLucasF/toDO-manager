import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/app.dart';
import 'package:task_manager/app/providers.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  final clock = FixedClock(DateTime(2026, 9, 24, 12));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: clock);
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> mouseDrag(WidgetTester tester, Offset from, Offset to) async {
    final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await settle(tester);
  }

  testWidgets('sidebar: a list dragged above another goes before it; onto a folder, into it', (tester) async {
    await tester.runAsync(() async {
      await repo.createList(name: 'Alfa');
      await repo.createList(name: 'Beta');
      await repo.createList(name: 'Gama');
      // A new folder goes after the lists.
      await repo.createFolder('Pasta');
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
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

    Future<List<String>> order() async {
      final s = (await tester.runAsync(repo.loadSnapshot))!;
      final top = [
        for (final f in s.activeFolders) (f.sortOrder, f.name),
        for (final l in s.activeLists)
          if (l.folderId == null && l.name != 'Inbox') (l.sortOrder, l.name),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      return [for (final e in top) e.$2];
    }

    expect(await order(), ['Alfa', 'Beta', 'Gama', 'Pasta']);
    // Gama onto the upper half of Alfa.
    final alfa = tester.getRect(find.text('Alfa'));
    await mouseDrag(tester, tester.getCenter(find.text('Gama')), Offset(alfa.center.dx, alfa.top + 2));
    expect(await order(), ['Gama', 'Alfa', 'Beta', 'Pasta']);

    // Beta onto the folder: it goes inside.
    await mouseDrag(tester, tester.getCenter(find.text('Beta')), tester.getCenter(find.text('Pasta')));
    final s = (await tester.runAsync(repo.loadSnapshot))!;
    final folder = s.activeFolders.single;
    expect(s.activeLists.singleWhere((l) => l.name == 'Beta').folderId, folder.id);
    expect(await order(), ['Gama', 'Alfa', 'Pasta']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(minutes: 2));
    debugDefaultTargetPlatformOverride = null;
  });
}
