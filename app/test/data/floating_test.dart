import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/core/time_zones.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/repository.dart';

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25, 10)));
  });
  tearDown(() => db.close());

  test('"Tempo flutuante": after a zone change the task keeps its clock time; fixed ones keep the instant', () async {
    final nineInNewYork = wallToLocal(DateTime(2026, 9, 28, 9), 'America/New_York');
    Future<String> task(String title, {required bool floating}) async {
      final id = await repo.createTask(listId: inboxListId, title: title);
      await repo.setSchedule(id, dueDate: nineInNewYork, isAllDay: false, timeZone: const Value('America/New_York'), isFloating: floating);
      return id;
    }

    final floating = await task('Flutuante', floating: true);
    final fixed = await task('Fixa', floating: false);

    expect(await repo.reanchorFloating('Asia/Tokyo'), 1);
    final moved = await repo.task(floating);
    expect(moved.dueDate!.toLocal(), DateTime(2026, 9, 28, 9), reason: '09:00 stays 09:00 on this device');
    expect((moved.timeZone, moved.isFloating), ('Asia/Tokyo', true));
    expect((await repo.task(fixed)).dueDate!.toLocal(), nineInNewYork);
    expect(await repo.reanchorFloating('Asia/Tokyo'), 0, reason: 'already in this zone');
  });
}
