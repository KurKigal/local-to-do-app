import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/tasks/data/reminder_repository.dart';
import '../database/app_database.dart';
import 'notification_service.dart';

abstract final class ReminderStartupRecovery {
  static Future<void> runIfNeeded() async {
    final documents =
        await getApplicationDocumentsDirectory();

    final marker = File(
      p.join(
        documents.path,
        '.flowtask_restore_pending',
      ),
    );

    if (!await marker.exists()) {
      return;
    }

    final database = AppDatabase();

    try {
      final reminders =
          ReminderRepository(
        database,
        NotificationService.instance,
      );

      await reminders
          .rescheduleAllFuture();

      await marker.delete();
    } finally {
      await database.close();
    }
  }
}
