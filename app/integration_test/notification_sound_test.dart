import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:task_manager/app/reminders.dart';
import 'package:task_manager/domain/focus.dart';
import 'package:task_manager/platform/notifications.dart';

/// On a real device (`flutter test integration_test -d windows`): schedules two end-of-Pomo
/// notifications with the system, the standard sound and "Alarme", and exits. They arrive with the app
/// closed; the alarm rings until "Parar".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('end-of-Pomo notifications scheduled with the system: standard and alarm', (tester) async {
    final service = NotificationService(notificationTexts(reminderTexts));
    await service.initialize(onResponse: (_) {});
    final now = DateTime.now();
    await service.schedule(
      id: 990001,
      taskId: focusNotificationTask,
      title: 'Teste: você tem um Pomo (som Padrão)',
      body: 'Descanse por 5 minutos.',
      at: now.add(const Duration(seconds: 12)),
      withActions: false,
    );
    await service.schedule(
      id: 990002,
      taskId: focusNotificationTask,
      title: 'Teste: você tem um Pomo (Alarme)',
      body: 'Toca até você clicar em Parar.',
      at: now.add(const Duration(seconds: 28)),
      withActions: false,
      sound: PomoSound.alarm,
    );
  });
}
