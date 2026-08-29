import '../../../core/storage/attachment_storage.dart';
import '../../../core/widget/flowtask_widget_service.dart';
import '../../tasks/data/reminder_repository.dart';
import 'trash_repository.dart';

class TrashService {
  TrashService({
    required TrashRepository trash,
    required ReminderRepository reminders,
    required AttachmentStorage storage,
    required FlowTaskWidgetService widgets,
  })  : _trash = trash,
        _reminders = reminders,
        _storage = storage,
        _widgets = widgets;

  final TrashRepository _trash;
  final ReminderRepository _reminders;
  final AttachmentStorage _storage;
  final FlowTaskWidgetService _widgets;

  Future<void> restore(
    String taskId,
  ) async {
    final task =
        await _trash.getTask(taskId);

    if (task == null ||
        task.deletedAt == null) {
      return;
    }

    await _trash.restoreRow(
      taskId,
    );

    await _reminders
        .rescheduleFutureForTask(
      taskId,
    );

    await _widgets.refresh();
  }

  Future<void> deleteForever(
    String taskId,
  ) async {
    final task =
        await _trash.getTask(taskId);

    if (task == null ||
        task.deletedAt == null) {
      return;
    }

    final attachments =
        await _trash.getAttachments(
      taskId,
    );

    // Cancel Android alarms before the cascade removes
    // reminder metadata.
    await _reminders
        .cancelScheduledForTask(
      taskId,
    );

    // Database is the source of truth. Delete it first.
    // Foreign-key cascade removes subtasks, reminders,
    // recurrence, task-tags and attachment metadata.
    await _trash.deleteForeverRow(
      taskId,
    );

    // Then reclaim physical app-private files.
    try {
      await _storage
          .deleteTaskDirectory(
        taskId,
      );
    } catch (_) {
      // Fallback to the paths captured before the DB cascade.
      for (final attachment
          in attachments) {
        try {
          await _storage.delete(
            attachment.relativePath,
          );
        } catch (_) {
          // Best effort. Orphan cleanup can retry later.
        }
      }
    }

    await _widgets.refresh();
  }

  Future<int> emptyTrash() async {
    final tasks =
        await _trash.getTrash();

    var deleted = 0;

    for (final task in tasks) {
      await deleteForever(
        task.id,
      );

      deleted++;
    }

    return deleted;
  }

  Future<int>
      cleanupOrphanAttachments() async {
    final validTaskIds =
        await _trash
            .getAllExistingTaskIds();

    return _storage
        .cleanupOrphanTaskDirectories(
      validTaskIds: validTaskIds,
    );
  }
}
