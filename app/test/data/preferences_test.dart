import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/core/clock.dart';
import 'package:task_manager/data/db/database.dart';
import 'package:task_manager/data/preferences_repository.dart';
import 'package:task_manager/data/repository.dart';
import 'package:task_manager/domain/enums.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/domain/reminder_plan.dart';
import 'package:task_manager/features/templates/templates.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  late AppDatabase db;
  late PreferencesRepository prefs;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    prefs = PreferencesRepository(db, clock: FixedClock(DateTime(2026, 9, 25)));
  });
  tearDown(() => db.close());

  test('notification and view preferences round-trip, invalid rows fall back', () async {
    var p = await prefs.watch().first;
    expect((p.dateDisplay, p.dailyAlert, p.constantReminder), (DateDisplay.date, null, false));

    await prefs.setDateDisplay(DateDisplay.countdown);
    await prefs.setDailyAlert(9 * 60);
    await prefs.setConstantReminder(enabled: true);
    p = await prefs.watch().first;
    expect((p.dateDisplay, p.dailyAlert, p.constantReminder), (DateDisplay.countdown, 540, true));

    await prefs.setDailyAlert(null);
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(PreferencesCompanion.insert(name: 'view.dateDisplay', value: '"sideways"', updatedAt: DateTime.utc(2026)));
    p = await prefs.watch().first;
    expect((p.dateDisplay, p.dailyAlert), (DateDisplay.date, null));
  });

  test('the despertador, the tray and starting with Windows: defaults and saved values', () async {
    var p = await prefs.watch().first;
    expect((p.reminderSound, p.closeToTray, p.launchAtStartup), (ReminderSound.alarmClock, true, false));
    expect(p.focus.sound, PomoSound.alarm, reason: 'the Pomo rings the despertador by default');

    await prefs.setReminderSound(ReminderSound.silent);
    await prefs.setCloseToTray(enabled: false);
    await prefs.setLaunchAtStartup(enabled: true);
    p = await prefs.watch().first;
    expect((p.reminderSound, p.closeToTray, p.launchAtStartup), (ReminderSound.silent, false, true));
  });

  test('built-in templates are created once', () async {
    final repo = Repository(db, clock: FixedClock(DateTime(2026, 9, 25)));
    final t = AppLocalizationsPt();
    await seedBuiltInTemplates(repo, prefs, t);
    await seedBuiltInTemplates(repo, prefs, t);
    final templates = await repo.watchTemplates().first;
    expect(templates.map((x) => x.name), [
      'Tarefas antes do trabalho',
      'Daily record',
      'Coisas para embalar para viajar',
      // "Modelo de nota".
      'Revisão Semanal',
      'Nota de leitura',
      'Nota de Reunião',
    ]);
    expect(templates.where((x) => x.kind == TaskKind.note), hasLength(3));
    expect(templates.first.items.split('\n'), hasLength(7));
    // Deleting them does not bring them back.
    for (final x in templates) {
      await repo.deleteTemplate(x.id);
    }
    await seedBuiltInTemplates(repo, prefs, t);
    expect(await repo.watchTemplates().first, isEmpty);
  });
}
