import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/reminders.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/core/ids.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/reminder_plan.dart';
import 'package:task_manager/domain/reminders.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';
import 'package:task_manager/platform/notifications.dart';
import 'package:task_manager/platform/reminder_scheduler.dart';

class _FakeGateway implements NotificationGateway {
  final scheduled = <int, PlannedReminder>{};
  final cancelled = <int>[];

  @override
  Future<void> schedule(PlannedReminder reminder) async => scheduled[reminder.id] = reminder;

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }
}

void main() {
  late AppDatabase db;
  late Repository repo;
  final now = DateTime(2026, 9, 25, 10);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db, clock: FixedClock(now));
  });
  tearDown(() => db.close());

  group('planReminders', () {
    test('"Lembrete constante" of one task: its notifications stay, the marker does not fire', () async {
      final id = await repo.createTask(
        listId: inboxListId,
        title: 'Remédio',
        dueDate: DateTime(2026, 9, 25, 15),
        isAllDay: false,
        reminders: [ReminderPresets.onTime, ReminderPresets.constant],
      );
      await repo.createTask(
        listId: inboxListId,
        title: 'Outra',
        dueDate: DateTime(2026, 9, 25, 16),
        isAllDay: false,
        reminders: [ReminderPresets.onTime],
      );
      final plan = planReminders(await repo.loadSnapshot(), now);
      expect([for (final r in plan) (r.title, r.persistent)], [('Remédio', true), ('Outra', false)]);
      expect(plan.first.taskId, id);
    });

    test('fires relative to the due date, skips past, closed and archived', () async {
      final timed = await repo.createTask(
        listId: inboxListId,
        title: 'Reunião',
        dueDate: DateTime(2026, 9, 25, 15),
        isAllDay: false,
        reminders: [ReminderPresets.onTime, ReminderPresets.oneDayBefore],
      );
      final allDay = await repo.createTask(
        listId: inboxListId,
        title: 'Aniversário',
        dueDate: DateTime(2026, 9, 27),
        reminders: [ReminderPresets.oneDayBeforeAt9],
      );
      final done = await repo.createTask(
        listId: inboxListId,
        title: 'Feita',
        dueDate: DateTime(2026, 9, 26, 9),
        isAllDay: false,
        reminders: ['PT0S'],
      );
      await repo.complete(done);
      final archived = await repo.createList(name: 'Velha');
      await repo.createTask(listId: archived, title: 'Arquivada', dueDate: DateTime(2026, 9, 26, 9), isAllDay: false, reminders: ['PT0S']);
      await repo.archiveList(archived, archived: true);

      final plan = planReminders(await repo.loadSnapshot(), now);
      expect(plan.map((r) => (r.taskId, r.at)), [(timed, DateTime(2026, 9, 25, 15)), (allDay, DateTime(2026, 9, 26, 9))]);
      expect(plan.first.id, notificationId(timed, ReminderPresets.onTime));
    });

    test('"No fim" fires at the end of a task with a duration', () async {
      final id = await repo.createTask(
        listId: inboxListId,
        title: 'Workshop',
        startDate: DateTime(2026, 9, 25, 14),
        dueDate: DateTime(2026, 9, 25, 16, 30),
        isAllDay: false,
        reminders: ['PT0S', ReminderPresets.atEnd],
      );
      final plan = planReminders(await repo.loadSnapshot(), now).where((r) => r.taskId == id);
      expect(plan.map((r) => r.at), [DateTime(2026, 9, 25, 14), DateTime(2026, 9, 25, 16, 30)]);
    });

    test('a snoozed reminder fires at the snooze time', () async {
      final id = await repo.createTask(listId: inboxListId, title: 'T', dueDate: DateTime(2026, 9, 25, 9, 50), isAllDay: false, reminders: ['PT0S']);
      await repo.snooze(id, DateTime(2026, 9, 25, 10, 5));
      final plan = planReminders(await repo.loadSnapshot(), now);
      expect(plan.single.id, notificationId(id, snoozeKey));
      expect(plan.single.at, DateTime(2026, 9, 25, 10, 5));
      // Rescheduling drops the snooze.
      await repo.setDueDate(id, DateTime(2026, 9, 26, 9), isAllDay: false);
      expect((await repo.task(id)).snoozeUntil, isNull);
    });

    test('notification ids are stable and positive', () {
      expect(notificationId('a', 'PT0S'), notificationId('a', 'PT0S'));
      expect(notificationId('a', 'PT0S'), isNot(notificationId('a', '-PT5M')));
      expect(notificationId('0199a7c2-7e3b-7000-8000-000000000000', 'PT0S'), inInclusiveRange(0, 0x7fffffff));
    });
  });

  group('ReminderScheduler', () {
    PlannedReminder reminder(String task, DateTime at, {String title = 'T'}) =>
        PlannedReminder(id: notificationId(task, 'PT0S'), taskId: task, at: at, title: title, due: at, isAllDay: false);

    test('schedules new, keeps unchanged, replaces changed, cancels removed', () async {
      final gateway = _FakeGateway();
      final store = MemoryScheduledStore();
      final scheduler = ReminderScheduler(gateway, store);
      final a = reminder('a', DateTime(2026, 9, 25, 15));
      final b = reminder('b', DateTime(2026, 9, 25, 16));
      await scheduler.sync([a, b], now: now, keepFired: (_) => true);
      expect(gateway.scheduled.keys, unorderedEquals([a.id, b.id]));

      gateway.scheduled.clear();
      await scheduler.sync([a, b], now: now, keepFired: (_) => true);
      expect(gateway.scheduled, isEmpty, reason: 'nothing changed');

      final renamed = reminder('a', DateTime(2026, 9, 25, 15), title: 'Novo');
      await scheduler.sync([renamed], now: now, keepFired: (_) => true);
      expect(gateway.cancelled, unorderedEquals([a.id, b.id]));
      expect(gateway.scheduled[a.id]!.title, 'Novo');
      expect(store.value.keys, [a.id]);
    });

    test('fired notifications stay while the task is open and go when it closes', () async {
      final gateway = _FakeGateway();
      final scheduler = ReminderScheduler(gateway, MemoryScheduledStore());
      final a = reminder('a', DateTime(2026, 9, 25, 10, 30));
      await scheduler.sync([a], now: now, keepFired: (_) => true);

      final later = DateTime(2026, 9, 25, 11);
      await scheduler.sync([], now: later, keepFired: (_) => true);
      expect(gateway.cancelled, isEmpty);

      await scheduler.sync([], now: later, keepFired: (_) => false);
      expect(gateway.cancelled, [a.id]);
    });
  });

  group('notification responses', () {
    test('encode and decode on both platforms', () {
      final complete = ReminderResponse.encode(NotificationAction.complete, 'task-1');
      final open = ReminderResponse.encode(NotificationAction.open, 'task-1');
      // Android: button id + payload.
      expect(
        ReminderResponse.decode(
          NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotificationAction, actionId: complete, payload: open),
        ),
        const ReminderResponse(NotificationAction.complete, 'task-1'),
      );
      // Android body tap: no button id.
      expect(
        ReminderResponse.decode(NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: open)),
        const ReminderResponse(NotificationAction.open, 'task-1'),
      );
      // Windows: the same arguments in both fields.
      expect(
        ReminderResponse.decode(
          NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, actionId: complete, payload: complete),
        ),
        const ReminderResponse(NotificationAction.complete, 'task-1'),
      );
      expect(
        ReminderResponse.decode(NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: 'x')),
        isNull,
      );
    });

    test('complete and snooze act on open tasks only', () async {
      final a = await repo.createTask(listId: inboxListId, title: 'A', dueDate: DateTime(2026, 9, 25, 10), isAllDay: false);
      await applyReminderResponse(repo, ReminderResponse(NotificationAction.snooze, a), now);
      expect((await repo.task(a)).snoozeUntil!.toLocal(), now.add(snoozeDuration));
      expect((await repo.task(a)).dueDate!.toLocal(), DateTime(2026, 9, 25, 10), reason: 'snoozing keeps the date');

      await applyReminderResponse(repo, ReminderResponse(NotificationAction.complete, a), now);
      expect((await repo.task(a)).status, TaskStatus.completed);

      await applyReminderResponse(repo, const ReminderResponse(NotificationAction.complete, 'missing'), now);
    });
  });

  group('daily digest and persistent reminders', () {
    test('one digest per day with tasks, overdue included, only future times', () async {
      await repo.createTask(listId: inboxListId, title: 'Atrasada', dueDate: DateTime(2026, 9, 23));
      await repo.createTask(listId: inboxListId, title: 'Hoje', dueDate: DateTime(2026, 9, 25));
      await repo.createTask(listId: inboxListId, title: 'Sábado', dueDate: DateTime(2026, 9, 26));
      final s = await repo.loadSnapshot();

      // 09:00 already passed at 10:00: the first digest is tomorrow.
      final morning = planDailyDigests(s, now, 9 * 60, days: 2);
      expect(morning.single.at, DateTime(2026, 9, 26, 9));
      expect(morning.single.tasks.map((t) => t.title), ['Atrasada', 'Hoje', 'Sábado']);

      final evening = planDailyDigests(s, now, 20 * 60, days: 2);
      expect(evening.first.tasks.map((t) => t.title), ['Atrasada', 'Hoje']);

      final prefs = Preferences(
        smartListVisibility: Preferences.defaults.smartListVisibility,
        theme: Preferences.defaults.theme,
        inboxVisibility: Preferences.defaults.inboxVisibility,
        dailyAlert: 20 * 60,
      );
      final digests = dailyDigestReminders(s, prefs, now, AppLocalizationsPt());
      expect(digests.first.title, 'Você tem 2 tarefas para hoje');
      expect(digests.first.body, 'Atrasada, Hoje');
      expect(digests.first.isDigest, isTrue);
    });

    test('the persistent flag reaches the plan and changes the signature', () async {
      await repo.createTask(listId: inboxListId, title: 'T', dueDate: DateTime(2026, 9, 25, 15), isAllDay: false, reminders: ['PT0S']);
      final s = await repo.loadSnapshot();
      final normal = planReminders(s, now).single;
      final persistent = planReminders(s, now, persistent: true).single;
      expect(persistent.persistent, isTrue);
      expect(persistent.signature, isNot(normal.signature), reason: 'toggling reschedules');
    });
  });

  group('checklist item reminders', () {
    test('an item with a time reminds; checking it drops the reminder and the fired notification', () async {
      final task = await repo.createTask(listId: inboxListId, title: 'Viagem', kind: TaskKind.checklist);
      final item = await repo.addChecklistItem(task, title: 'Passaporte');
      final other = await repo.addChecklistItem(task, title: 'Carregador');
      await repo.setChecklistItemDate(item, DateTime(2026, 9, 25, 15), isAllDay: false);
      await repo.setChecklistItemDate(other, DateTime(2026, 9, 26));
      var s = await repo.loadSnapshot();
      final plan = planReminders(s, now);
      expect(plan.map((r) => (r.title, r.at, r.itemId != null)), [
        ('Passaporte', DateTime(2026, 9, 25, 15), true),
        ('Carregador', DateTime(2026, 9, 26, 9), true),
      ]);
      expect(plan.first.body, 'Viagem');
      expect(keepsFiredReminders(s, plan.first.owner), isTrue);

      await applyReminderResponse(repo, ReminderResponse(NotificationAction.complete, task, item), now);
      s = await repo.loadSnapshot();
      expect(s.itemsOf(task).firstWhere((i) => i.id == item).isCompleted, isTrue);
      expect(planReminders(s, now).map((r) => r.title), ['Carregador']);
      expect(keepsFiredReminders(s, plan.first.owner), isFalse);
    });

    test('item responses round-trip through the payload', () {
      final encoded = ReminderResponse.encode(NotificationAction.complete, 'task-1', 'item-9');
      expect(
        ReminderResponse.decode(
          NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotificationAction, actionId: encoded),
        ),
        const ReminderResponse(NotificationAction.complete, 'task-1', 'item-9'),
      );
    });
  });
}
