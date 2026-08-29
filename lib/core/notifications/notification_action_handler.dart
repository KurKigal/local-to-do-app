import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/tasks/data/recurrence_service.dart';
import '../../features/tasks/data/reminder_repository.dart';
import '../../features/tasks/data/task_repository.dart';
import '../../features/tasks/data/task_service.dart';
import '../database/app_database.dart';
import 'notification_service.dart';
import 'time_zone_service.dart';
import '../widget/flowtask_widget_service.dart';

@pragma('vm:entry-point')
void notificationBackgroundHandler(
  NotificationResponse response,
) async {
  final payload =
      NotificationPayload.decode(
    response.payload,
  );

  if (payload == null ||
      payload.taskId == '__test__') {
    return;
  }

  await TimeZoneService.initialize();

  final database = AppDatabase();

  try {
    final tasks =
        TaskRepository(database);

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

    final taskService =
        TaskService(
      tasks: tasks,
      reminders: reminders,
      recurrences: recurrences,
      widgets:
          FlowTaskWidgetService(
        database,
      ),
    );

    switch (response.actionId) {
      case NotificationService
          .doneActionId:
        await taskService.setCompleted(
          payload.taskId,
          completed: true,
        );

        break;

      case NotificationService
          .snoozeActionId:
        final reminderId =
            payload.reminderId;

        if (reminderId == null) {
          return;
        }

        await reminders.snooze(
          reminderId,
          duration:
              const Duration(
            minutes: 10,
          ),
        );

        break;
    }
  } finally {
    await database.close();
  }
}
