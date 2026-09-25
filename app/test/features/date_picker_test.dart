import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/app/theme/app_theme.dart';
import 'package:task_manager/core/time_zones.dart';
import 'package:task_manager/domain/recurrence.dart';
import 'package:task_manager/domain/reminders.dart';
import 'package:task_manager/features/date_picker/date_picker.dart';
import 'package:task_manager/l10n/app_localizations.dart';
import 'package:task_manager/l10n/app_localizations_pt.dart';

void main() {
  final t = AppLocalizationsPt();
  final now = DateTime(2026, 9, 25, 10, 12);

  group('rule helpers', () {
    test('presets follow the chosen day', () {
      final presets = repeatPresets(t, DateTime(2026, 9, 25));
      expect(presets['FREQ=DAILY;INTERVAL=1'], 'Diariamente');
      expect(presets.containsKey('FREQ=WEEKLY;INTERVAL=1;BYDAY=FR'), isTrue);
      expect(presets.containsKey('FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=25'), isTrue);
      expect(presets.containsKey('FREQ=YEARLY;INTERVAL=1;BYMONTH=9;BYMONTHDAY=25'), isTrue);
    });

    test('end of repetition: count, until and forever', () {
      const rule = 'FREQ=DAILY;INTERVAL=1';
      expect(withEnd(rule, count: 3), 'FREQ=DAILY;INTERVAL=1;COUNT=3');
      expect(ruleCount(withEnd(rule, count: 3)), 3);
      final until = withEnd(rule, until: DateTime(2026, 10, 31));
      expect(until, 'FREQ=DAILY;INTERVAL=1;UNTIL=20261031T235959Z');
      expect(ruleUntil(until), DateTime(2026, 10, 31));
      expect(withEnd(until), rule);
      expect(isValidRule(until), isTrue);
    });

    test('labels: preset names, custom rules and custom reminders', () {
      final day = DateTime(2026, 9, 25);
      expect(repeatLabel(t, 'FREQ=DAILY;INTERVAL=1;COUNT=4', day), 'Diariamente');
      expect(repeatLabel(t, 'FREQ=DAILY;INTERVAL=3', day), t.repeatCustom);
      expect(reminderLabel(t, ReminderPresets.onTime), t.reminderOnTime);
      expect(reminderLabel(t, '-PT2H'), t.reminderCustomValue(2, t.unitHours.toLowerCase()));
      expect(reminderLabel(t, '-P3D'), t.reminderCustomValue(3, t.unitDays.toLowerCase()));
    });
  });

  Future<DateSelection?> openPicker(WidgetTester tester, DateSelection initial, Future<void> Function() interact, {bool withZone = false}) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateSelection? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark: true),
        locale: const Locale('pt', 'BR'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showTtDatePicker(context, initial: initial, now: now, withZone: withZone);
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await interact();
    expect(closed, isTrue);
    return result;
  }

  testWidgets('picking a day and a time adds the "Na hora" reminder', (tester) async {
    final result = await openPicker(tester, const DateSelection(), () async {
      expect(find.text('Setembro 2026'), findsOneWidget);
      await tester.tap(find.text('28'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.pickerTime));
      await tester.pumpAndSettle();
      await tester.tap(find.text('11:00').last);
      await tester.pumpAndSettle();
      expect(find.text(t.reminderOnTime), findsOneWidget);
      await tester.tap(find.text(t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.dueDate, DateTime(2026, 9, 28, 11));
    expect(result.isAllDay, isFalse);
    expect(result.reminders, {ReminderPresets.onTime});
  });

  testWidgets('"Fuso horário": a fixed zone shows its clock; "Tempo flutuante" keeps the clock time', (tester) async {
    final nineInTokyo = wallToLocal(DateTime(2026, 9, 28, 9), 'Asia/Tokyo');
    final initial = DateSelection(dueDate: nineInTokyo, isAllDay: false, timeZone: 'Asia/Tokyo');
    final fixed = await openPicker(tester, initial, withZone: true, () async {
      expect(find.text('Tokyo, GMT+9'), findsOneWidget);
      expect(find.textContaining('09:00'), findsWidgets);
      await tester.tap(find.text(t.actionOk));
      await tester.pumpAndSettle();
    });
    expect((fixed!.dueDate, fixed.timeZone, fixed.isFloating), (nineInTokyo, 'Asia/Tokyo', false));

    final floating = await openPicker(tester, initial, withZone: true, () async {
      await tester.tap(find.text(t.pickerTimeZone));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.zoneFloating));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.actionOk).last);
      await tester.pumpAndSettle();
      expect(find.text(t.zoneFloating), findsOneWidget);
      await tester.tap(find.text(t.actionOk));
      await tester.pumpAndSettle();
    });
    expect((floating!.dueDate, floating.timeZone, floating.isFloating), (DateTime(2026, 9, 28, 9), null, true));

    // Without the setting there is no row, and the zone passes through.
    final plain = await openPicker(tester, initial, () async {
      expect(find.text(t.pickerTimeZone), findsNothing);
      await tester.tap(find.text(t.actionOk));
      await tester.pumpAndSettle();
    });
    expect((plain!.dueDate, plain.timeZone), (nineInTokyo, 'Asia/Tokyo'));
  });

  testWidgets('repeat preset and "Limpar"', (tester) async {
    final result = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 25)), () async {
      await tester.tap(find.text(t.pickerRepeat));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diariamente'));
      await tester.pumpAndSettle();
      expect(find.text(t.repeatEnds), findsOneWidget);
      await tester.tap(find.text(t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.repeatRule, 'FREQ=DAILY;INTERVAL=1');
    expect(result.repeatFrom, RepeatFrom.dueDate);

    final cleared = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 25), repeatRule: 'FREQ=DAILY;INTERVAL=1'), () async {
      await tester.tap(find.text(t.dateClear));
      await tester.pumpAndSettle();
    });
    expect(cleared!.dueDate, isNull);
  });

  testWidgets('a time can be typed in the "Hora" field', (tester) async {
    final result = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 26)), () async {
      await tester.tap(find.text(t.pickerTime));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '14h45');
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.dueDate, DateTime(2026, 9, 26, 14, 45));
    expect(result.isAllDay, isFalse);
  });

  testWidgets('custom repetition: monthly on the 4th Friday keeps the end count', (tester) async {
    final result = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 25), repeatRule: 'FREQ=DAILY;INTERVAL=1;COUNT=3'), () async {
      await tester.tap(find.text(t.pickerRepeat));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.repeatCustom).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.unitDay));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.unitMonth).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.repeatMonthOn));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.repeatRule, 'FREQ=MONTHLY;INTERVAL=1;BYDAY=4FR;COUNT=3');
  });

  testWidgets('custom repetition on specific dates moves the task to the first one', (tester) async {
    final result = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 25)), () async {
      await tester.tap(find.text(t.pickerRepeat));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.repeatCustom).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.repeatFromDue));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.repeatSpecificDates).last);
      await tester.pumpAndSettle();
      // The 25th starts selected (the task date); pick the 28th and the 30th, drop the 25th.
      final dialog = find.byType(AlertDialog);
      for (final day in ['28', '30', '25']) {
        await tester.tap(find.descendant(of: dialog, matching: find.text(day)).last);
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk).last);
      await tester.pumpAndSettle();
      expect(find.text(t.repeatEnds), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.repeatRule, 'DATES=20260928,20260930');
    expect(result.dueDate, DateTime(2026, 9, 28));
  });

  testWidgets('Duração: first tap sets the start, the second the end', (tester) async {
    final result = await openPicker(tester, DateSelection(dueDate: DateTime(2026, 9, 25)), () async {
      await tester.tap(find.text(t.pickerTabDuration));
      await tester.pumpAndSettle();
      await tester.tap(find.text('26'));
      await tester.pump();
      await tester.tap(find.text('28'));
      await tester.pump();
      expect(find.text(t.pickerStart), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.startDate, DateTime(2026, 9, 26));
    expect(result.dueDate, DateTime(2026, 9, 28));
    expect(result.isAllDay, isTrue);
  });

  testWidgets('Duração opens on the stored range and "Dia inteiro" off gives times', (tester) async {
    final result = await openPicker(tester, DateSelection(startDate: DateTime(2026, 9, 26), dueDate: DateTime(2026, 9, 28)), () async {
      expect(find.text(t.pickerEnd), findsOneWidget, reason: 'opens on the Duração tab');
      await tester.tap(find.text(t.pickerAllDay));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, t.actionOk));
      await tester.pumpAndSettle();
    });
    expect(result!.isAllDay, isFalse);
    expect(result.startDate, DateTime(2026, 9, 26, 10, 30));
    expect(result.dueDate, DateTime(2026, 9, 28, 11, 30));
    expect(result.reminders, {'PT0S'});
  });
}
