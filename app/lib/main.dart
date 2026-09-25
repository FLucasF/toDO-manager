import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/reminders.dart';
import 'data/attachment_store.dart';
import 'data/db/database.dart';
import 'data/subscription_store.dart';
import 'features/backup/auto_backup.dart';
import 'features/countdown/countdown_card.dart';
import 'features/subscriptions/subscriptions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = await initializeReminders();
  final support = await getApplicationSupportDirectory();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(AppDatabase()),
        reminderSetupProvider.overrideWithValue(reminders),
        attachmentStoreProvider.overrideWithValue(AttachmentStore(Directory(p.join(support.path, 'attachments')))),
        subscriptionStoreProvider.overrideWithValue(SubscriptionStore(Directory(p.join(support.path, 'calendars')))),
        countdownImagesProvider.overrideWithValue(Directory(p.join(support.path, 'countdown_images'))),
        autoBackupProvider.overrideWithValue(AutoBackup(Directory(p.join(support.path, 'backups')))),
      ],
      child: const TasksApp(),
    ),
  );
}
