import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/time_zones.dart';
import '../domain/focus.dart';
import '../domain/reminder_plan.dart';

/// Android's FLAG_INSISTENT: the sound repeats until the notification is opened or cancelled.
const _flagInsistent = 4;

/// The "task" of the focus notifications: tapping them opens Foco.
const focusNotificationTask = 'focus:';

/// What the user did with a reminder notification.
enum NotificationAction { open, complete, snooze }

/// A notification tap or button press, decoded.
class ReminderResponse {
  const ReminderResponse(this.action, this.taskId, [this.itemId]);

  final NotificationAction action;
  final String taskId;

  /// Set when the notification is the reminder of a checklist item.
  final String? itemId;

  /// Buttons and payloads carry `action|taskId[|itemId]`: Windows returns only the pressed button's
  /// arguments, Android returns the button id and the payload.
  static String encode(NotificationAction action, String taskId, [String? itemId]) =>
      itemId == null ? '${action.name}|$taskId' : '${action.name}|$taskId|$itemId';

  static ReminderResponse? decode(NotificationResponse r) => _parse(r.actionId) ?? _parse(r.payload);

  static ReminderResponse? _parse(String? value) {
    final parts = value?.split('|');
    if (parts == null || parts.length < 2 || parts.length > 3 || parts[1].isEmpty) return null;
    final action = NotificationAction.values.where((a) => a.name == parts[0]).firstOrNull;
    return action == null ? null : ReminderResponse(action, parts[1], parts.length == 3 ? parts[2] : null);
  }

  @override
  bool operator ==(Object other) => other is ReminderResponse && other.action == action && other.taskId == taskId && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(action, taskId, itemId);
}

/// Texts of the reminder notifications, localized by the caller.
class NotificationTexts {
  const NotificationTexts({
    required this.appName,
    required this.channelName,
    required this.channelDescription,
    required this.silentChannelName,
    required this.alarmChannelName,
    required this.alarmClockChannelName,
    required this.focusChannelName,
    required this.complete,
    required this.snooze,
    required this.stop,
  });

  final String appName;
  final String channelName;
  final String channelDescription;

  /// Android channel of the silent end of Pomo ("Som do Pomo" › Silencioso).
  final String silentChannelName;

  /// Android channel of "Som do Pomo" › Despertador: it rings on the alarm volume until opened.
  final String alarmChannelName;

  /// Android channel of the reminders with "Som do lembrete" › Despertador.
  final String alarmClockChannelName;

  /// Android channel of the running focus timer in the notification shade.
  final String focusChannelName;
  final String complete;
  final String snooze;

  /// "Parar": the button that stops an alarm.
  final String stop;
}

/// Sets the local time zone used to schedule notifications.
Future<void> initializeTimeZone() async {
  tz_data.initializeTimeZones();
  final zone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(zone.identifier));
  setDeviceZone(zone.identifier);
}

/// Operating-system reminders (validated by the Phase 0 risk tests).
///
/// Both Android and Windows schedule with the OS: reminders fire with the app closed and can be
/// cancelled. On Windows without MSIX, [pending] returns an empty list,
/// which is why the scheduler keeps its own record of what it scheduled.
class NotificationService {
  NotificationService(this.texts, [FlutterLocalNotificationsPlugin? plugin]) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final NotificationTexts texts;
  final FlutterLocalNotificationsPlugin _plugin;

  /// [onResponse] runs when the user taps a notification or one of its buttons while the app runs;
  /// [onBackgroundResponse] (a top-level `vm:entry-point` function) handles Android buttons with the
  /// app closed.
  Future<void> initialize({
    required void Function(NotificationResponse) onResponse,
    void Function(NotificationResponse)? onBackgroundResponse,
  }) async {
    await initializeTimeZone();
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        windows: WindowsInitializationSettings(
          appName: texts.appName,
          appUserModelId: 'Dev.LucasFelipe.Tarefas',
          guid: '45ccb216-991f-421f-ad02-f0856c887a8b',
        ),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
  }

  /// The notification that launched the app, if any.
  Future<NotificationResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details?.notificationResponse : null;
  }

  /// Asks for notification and exact-alarm permissions (Android 13+ prompts the user).
  /// Returns whether reminders can be scheduled at the exact time.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final canNotify = await android.requestNotificationsPermission() ?? false;
    final canExact = await android.canScheduleExactNotifications() ?? false;
    return canNotify && (canExact || (await android.requestExactAlarmsPermission() ?? false));
  }

  /// [withActions] adds "Concluído" / "Adiar"; [persistent] keeps the notification until the user acts
  /// (Android: ongoing, not auto-cancelled; Windows: reminder scenario, stays on screen).
  /// [withActions] adds "Concluído" and, unless [canSnooze] is false, "Adiar"; [persistent] keeps the
  /// notification until the user acts (Android: ongoing, not auto-cancelled; Windows: reminder scenario).
  NotificationDetails _details(
    String taskId, {
    String? itemId,
    bool withActions = true,
    bool canSnooze = true,
    bool persistent = false,
    PomoSound sound = PomoSound.standard,
    ReminderSound reminderSound = ReminderSound.standard,
    bool muted = false,
  }) {
    final complete = ReminderResponse.encode(NotificationAction.complete, taskId, itemId);
    final snooze = ReminderResponse.encode(NotificationAction.snooze, taskId, itemId);
    final silent = sound == PomoSound.silent || reminderSound == ReminderSound.silent;
    final alarm = sound == PomoSound.alarm;
    final clock = reminderSound == ReminderSound.alarmClock;
    final open = ReminderResponse.encode(NotificationAction.open, taskId, itemId);
    final channel = switch (null) {
      _ when alarm => ('focus_despertador', texts.alarmChannelName),
      _ when clock => ('reminders_despertador', texts.alarmClockChannelName),
      _ when silent => ('reminders_silent', texts.silentChannelName),
      _ => ('reminders', texts.channelName),
    };
    return NotificationDetails(
      // Android channels fix their sound: the "Despertador" (the app's sound) and silence use channels
      // of their own; the other choices sound like any reminder.
      android: AndroidNotificationDetails(
        channel.$1,
        channel.$2,
        channelDescription: texts.channelDescription,
        playSound: !silent,
        sound: alarm || clock ? const RawResourceAndroidNotificationSound('despertador') : null,
        // The Pomo's despertador rings on the alarm volume and repeats until the notification is opened.
        audioAttributesUsage: alarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        additionalFlags: alarm ? Int32List.fromList([_flagInsistent]) : null,
        importance: Importance.max,
        priority: Priority.high,
        category: alarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        ongoing: persistent,
        autoCancel: !persistent,
        actions: withActions
            ? [AndroidNotificationAction(complete, texts.complete), if (canSnooze) AndroidNotificationAction(snooze, texts.snooze)]
            : null,
      ),
      windows: WindowsNotificationDetails(
        // "Alarme" rings until stopped, as an alarm clock: Windows wants the alarm scenario and a button.
        scenario: alarm ? WindowsNotificationScenario.alarm : (persistent ? WindowsNotificationScenario.reminder : null),
        // Windows toasts of an installed app only play Windows' sounds: the app plays the despertador
        // itself when it runs ([muted] then), and these ring when it is closed.
        audio: switch (sound) {
          _ when muted => WindowsNotificationAudio.silent(),
          _ when reminderSound == ReminderSound.silent => WindowsNotificationAudio.silent(),
          _ when clock => WindowsNotificationAudio.preset(sound: WindowsNotificationSound.reminder),
          PomoSound.standard => null,
          PomoSound.alarm => WindowsNotificationAudio.preset(sound: WindowsNotificationSound.alarm1, shouldLoop: true),
          PomoSound.reminder => WindowsNotificationAudio.preset(sound: WindowsNotificationSound.reminder),
          PomoSound.message => WindowsNotificationAudio.preset(sound: WindowsNotificationSound.im),
          PomoSound.silent => WindowsNotificationAudio.silent(),
        },
        actions: [
          if (withActions) ...[
            WindowsAction(content: texts.complete, arguments: complete),
            if (canSnooze) WindowsAction(content: texts.snooze, arguments: snooze),
          ],
          if (alarm) WindowsAction(content: texts.stop, arguments: open),
        ],
      ),
    );
  }

  Future<void> showNow({required int id, required String taskId, required String title, String? body}) => _plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: _details(taskId),
    payload: ReminderResponse.encode(NotificationAction.open, taskId),
  );

  Future<void> schedule({
    required int id,
    required String taskId,
    String? itemId,
    required String title,
    String? body,
    required DateTime at,
    bool withActions = true,
    bool persistent = false,
    PomoSound sound = PomoSound.standard,
    ReminderSound reminderSound = ReminderSound.standard,
    bool muted = false,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(at, tz.local),
    // A checklist item cannot be snoozed, only checked.
    notificationDetails: _details(
      taskId,
      itemId: itemId,
      withActions: withActions,
      canSnooze: itemId == null,
      persistent: persistent,
      sound: sound,
      reminderSound: reminderSound,
      muted: muted,
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: ReminderResponse.encode(NotificationAction.open, taskId, itemId),
  );

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Android: the running focus timer in the notification shade, counting down to [countdownTo] or up
  /// from [countUpFrom] by itself (no text when paused). Other platforms show nothing.
  Future<void> showFocusRunning({required int id, required String title, String? body, DateTime? countdownTo, DateTime? countUpFrom}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final when = countdownTo ?? countUpFrom;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: ReminderResponse.encode(NotificationAction.open, focusNotificationTask),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_running',
          texts.focusChannelName,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          ongoing: true,
          autoCancel: false,
          category: AndroidNotificationCategory.stopwatch,
          showWhen: when != null,
          when: when?.millisecondsSinceEpoch,
          usesChronometer: when != null,
          chronometerCountDown: countdownTo != null,
          // A countdown leaves the shade when it reaches zero, also with the app closed (it would go
          // on below zero); the end notification takes its place.
          timeoutAfter: countdownTo == null ? null : math.max(1, countdownTo.difference(DateTime.now()).inMilliseconds),
        ),
      ),
    );
  }

  Future<List<PendingNotificationRequest>> pending() => _plugin.pendingNotificationRequests();

  @visibleForTesting
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}
