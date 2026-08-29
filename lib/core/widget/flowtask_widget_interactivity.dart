import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/tasks/data/recurrence_service.dart';
import '../../features/tasks/data/reminder_repository.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/task_service.dart';
import '../database/app_database.dart';
import '../notifications/notification_action_handler.dart';
import '../notifications/notification_service.dart';
import '../notifications/time_zone_service.dart';
import 'flowtask_widget_service.dart';

@pragma('vm:entry-point')
Future<void> flowTaskWidgetBackgroundCallback(
  Uri? uri,
) async {
  WidgetsFlutterBinding
      .ensureInitialized();

  if (uri?.host != 'done') {
    return;
  }

  final taskId =
      uri?.queryParameters['taskId'];

  if (taskId == null ||
      taskId.isEmpty) {
    return;
  }

  await TimeZoneService.initialize();

  await NotificationService.instance
      .initialize(
    onOpenTask: (_) {},
    onBackgroundResponse:
        notificationBackgroundHandler,
  );

  final database =
      AppDatabase();

  try {
    final reminders =
        ReminderRepository(
      database,
      NotificationService.instance,
    );

    final recurrences =
        RecurrenceService(
      database: database,
      reminders: reminders,
    );

    final widgets =
        FlowTaskWidgetService(
      database,
    );

    final service = TaskService(
      tasks:
          TaskRepository(database),
      reminders: reminders,
      recurrences: recurrences,
      widgets: widgets,
    );

    await service.setCompleted(
      taskId,
      completed: true,
    );
  } finally {
    await database.close();
  }
}

abstract final class FlowTaskWidgetInteractivity {
  static Future<void> initialize() async {
    await HomeWidget
        .registerInteractivityCallback(
      flowTaskWidgetBackgroundCallback,
    );
  }
}
