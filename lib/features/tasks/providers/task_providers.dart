import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/storage/attachment_storage.dart';
import '../../../core/widget/flowtask_widget_service.dart';
import '../data/attachment_action_service.dart';
import '../data/attachment_repository.dart';
import '../data/recurrence_repository.dart';
import '../data/recurrence_service.dart';
import '../data/reminder_repository.dart';
import '../data/subtask_repository.dart';
import '../data/task_repository.dart';
import '../data/task_service.dart';

final taskRepositoryProvider =
    Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(databaseProvider),
  );
});

final todayTasksProvider =
    StreamProvider.autoDispose<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchToday();
});

final overdueTasksProvider =
    StreamProvider.autoDispose<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchOverdue();
});

final allTasksProvider =
    StreamProvider.autoDispose<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchAllActive();
});

final completedTasksProvider =
    StreamProvider.autoDispose<List<Task>>((ref) {
  return ref
      .watch(taskRepositoryProvider)
      .watchCompleted();
});

final taskProvider = StreamProvider.autoDispose
    .family<Task?, String>((ref, taskId) {
  return ref
      .watch(taskRepositoryProvider)
      .watchTask(taskId);
});

final subtaskRepositoryProvider =
    Provider<SubtaskRepository>((ref) {
  return SubtaskRepository(
    ref.watch(databaseProvider),
  );
});

final attachmentStorageProvider =
    Provider<AttachmentStorage>((ref) {
  return AttachmentStorage();
});

final attachmentRepositoryProvider =
    Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(
    database: ref.watch(databaseProvider),
    storage: ref.watch(
      attachmentStorageProvider,
    ),
  );
});

final attachmentActionServiceProvider =
    Provider<AttachmentActionService>((ref) {
  return AttachmentActionService(
    ref.watch(
      attachmentRepositoryProvider,
    ),
  );
});

final subtasksProvider = StreamProvider.autoDispose
    .family<List<Subtask>, String>(
  (ref, taskId) {
    return ref
        .watch(subtaskRepositoryProvider)
        .watchForTask(taskId);
  },
);

final attachmentsProvider = StreamProvider.autoDispose
    .family<List<Attachment>, String>(
  (ref, taskId) {
    return ref
        .watch(attachmentRepositoryProvider)
        .watchForTask(taskId);
  },
);

final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    ref.watch(databaseProvider),
    ref.watch(
      notificationServiceProvider,
    ),
  );
});

final remindersProvider = StreamProvider.autoDispose
    .family<List<Reminder>, String>(
  (ref, taskId) {
    return ref
        .watch(reminderRepositoryProvider)
        .watchForTask(taskId);
  },
);

final recurrenceRepositoryProvider =
    Provider<RecurrenceRepository>((ref) {
  return RecurrenceRepository(
    ref.watch(databaseProvider),
  );
});

final recurrenceProvider =
    StreamProvider.autoDispose
        .family<Recurrence?, String>(
  (ref, taskId) {
    return ref
        .watch(recurrenceRepositoryProvider)
        .watchForTask(taskId);
  },
);

final recurrenceServiceProvider =
    Provider<RecurrenceService>((ref) {
  return RecurrenceService(
    database: ref.watch(databaseProvider),
    reminders: ref.watch(
      reminderRepositoryProvider,
    ),
  );
});

final flowTaskWidgetServiceProvider =
    Provider<FlowTaskWidgetService>((ref) {
  return FlowTaskWidgetService(
    ref.watch(databaseProvider),
  );
});

final taskServiceProvider =
    Provider<TaskService>((ref) {
  return TaskService(
    tasks: ref.watch(
      taskRepositoryProvider,
    ),
    reminders: ref.watch(
      reminderRepositoryProvider,
    ),
    recurrences: ref.watch(
      recurrenceServiceProvider,
    ),
    widgets: ref.watch(
      flowTaskWidgetServiceProvider,
    ),
  );
});
