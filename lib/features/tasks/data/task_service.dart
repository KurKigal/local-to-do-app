import '../../../core/database/tables/tasks.dart';
import '../../../core/widget/flowtask_widget_service.dart';
import 'recurrence_service.dart';
import 'reminder_repository.dart';
import 'task_repository.dart';

class TaskService {
  TaskService({
    required TaskRepository tasks,
    required ReminderRepository reminders,
    required RecurrenceService recurrences,
    required FlowTaskWidgetService widgets,
  })  : _tasks = tasks,
        _reminders = reminders,
        _recurrences = recurrences,
        _widgets = widgets;

  final TaskRepository _tasks;
  final ReminderRepository _reminders;
  final RecurrenceService _recurrences;
  final FlowTaskWidgetService _widgets;

  Future<String> createTask({
    required String title,
    String? description,
    String? projectId,
    TaskPriority priority =
        TaskPriority.none,
    DateTime? dueAt,
    bool hasDueTime = false,
  }) async {
    final id =
        await _tasks.createTask(
      title: title,
      description: description,
      projectId: projectId,
      priority: priority,
      dueAt: dueAt,
      hasDueTime: hasDueTime,
    );

    await _widgets.refresh();

    return id;
  }

  Future<void> updateTask({
    required String id,
    required String title,
    String? description,
    String? projectId,
    required TaskPriority priority,
    DateTime? dueAt,
    required bool hasDueTime,
  }) async {
    await _tasks.updateTask(
      id: id,
      title: title,
      description: description,
      projectId: projectId,
      priority: priority,
      dueAt: dueAt,
      hasDueTime: hasDueTime,
    );

    await _reminders
        .recalculateRelativeAndReschedule(
      id,
    );

    await _widgets.refresh();
  }

  Future<void> setCompleted(
    String id, {
    required bool completed,
  }) async {
    await _tasks.setCompleted(
      id,
      completed: completed,
    );

    if (completed) {
      await _reminders
          .cancelScheduledForTask(id);

      await _recurrences
          .generateNextOccurrence(id);
    } else {
      await _reminders
          .rescheduleFutureForTask(id);
    }

    await _widgets.refresh();
  }

  Future<void> moveToTrash(
    String id,
  ) async {
    await _tasks.moveToTrash(id);

    await _reminders
        .cancelScheduledForTask(id);

    await _widgets.refresh();
  }

  Future<void> restore(
    String id,
  ) async {
    await _tasks.restore(id);

    await _reminders
        .rescheduleFutureForTask(id);

    await _widgets.refresh();
  }
}
