import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/reminders.dart';
import '../../../core/database/tables/tasks.dart';
import '../../../core/notifications/notification_service.dart';

class ReminderRepository {
  ReminderRepository(
    this._db,
    this._notifications,
  );

  final AppDatabase _db;
  final NotificationService _notifications;

  static const _uuid = Uuid();
  final Random _random = Random.secure();

  Stream<List<Reminder>> watchForTask(String taskId) {
    final query = _db.select(_db.reminders)
      ..where(
        (reminder) =>
            reminder.taskId.equals(taskId) & reminder.isEnabled.equals(true),
      )
      ..orderBy([
        (reminder) => OrderingTerm.asc(reminder.scheduledAt),
      ]);

    return query.watch();
  }

  Future<String> createRelative({
    required String taskId,
    required int minutesBeforeDue,
  }) async {
    if (minutesBeforeDue < 0) {
      throw ArgumentError('Reminder offset cannot be negative.');
    }

    final task = await _getTask(taskId);

    if (task == null) {
      throw StateError('Task not found.');
    }

    if (task.dueAt == null || !task.hasDueTime) {
      throw StateError(
        'Relative reminders require a due date and time.',
      );
    }

    final scheduledAt = task.dueAt!.subtract(
      Duration(minutes: minutesBeforeDue),
    );

    _requireFuture(scheduledAt);

    final duplicate = await (_db.select(_db.reminders)
          ..where(
            (reminder) =>
                reminder.taskId.equals(taskId) &
                reminder.kind.equalsValue(ReminderKind.relativeToDue) &
                reminder.offsetMinutes.equals(minutesBeforeDue) &
                reminder.isEnabled.equals(true),
          ))
        .getSingleOrNull();

    if (duplicate != null) {
      return duplicate.id;
    }

    return _insertAndSchedule(
      task: task,
      kind: ReminderKind.relativeToDue,
      scheduledAt: scheduledAt,
      offsetMinutes: minutesBeforeDue,
    );
  }

  Future<String> createAbsolute({
    required String taskId,
    required DateTime scheduledAt,
  }) async {
    _requireFuture(scheduledAt);

    final task = await _getTask(taskId);

    if (task == null) {
      throw StateError('Task not found.');
    }

    return _insertAndSchedule(
      task: task,
      kind: ReminderKind.absolute,
      scheduledAt: scheduledAt,
    );
  }

  Future<String> _insertAndSchedule({
    required Task task,
    required ReminderKind kind,
    required DateTime scheduledAt,
    int? offsetMinutes,
  }) async {
    final id = _uuid.v4();
    final notificationId = await _allocateNotificationId();

    await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            id: id,
            taskId: task.id,
            kind: Value(kind),
            scheduledAt: scheduledAt,
            offsetMinutes: Value(offsetMinutes),
            notificationId: notificationId,
            createdAt: DateTime.now(),
          ),
        );

    try {
      final reminder = await _getReminder(id);

      if (reminder == null) {
        throw StateError('Reminder could not be created.');
      }

      await _schedule(reminder, task);
      return id;
    } catch (_) {
      await (_db.delete(_db.reminders)
            ..where((reminder) => reminder.id.equals(id)))
          .go();
      rethrow;
    }
  }

  Future<void> delete(String reminderId) async {
    final reminder = await _getReminder(reminderId);

    if (reminder == null) {
      return;
    }

    await _notifications.cancel(reminder.notificationId);

    await (_db.delete(_db.reminders)
          ..where((row) => row.id.equals(reminderId)))
        .go();
  }

  Future<void> snooze(
    String reminderId, {
    Duration duration = const Duration(minutes: 10),
  }) async {
    final reminder = await _getReminder(reminderId);

    if (reminder == null || !reminder.isEnabled) {
      return;
    }

    final task = await _getTask(reminder.taskId);

    if (task == null ||
        task.deletedAt != null ||
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      return;
    }

    final snoozedUntil = DateTime.now().add(duration);

    await (_db.update(_db.reminders)
          ..where((row) => row.id.equals(reminderId)))
        .write(
      RemindersCompanion(
        snoozedUntil: Value(snoozedUntil),
      ),
    );

    final updated = await _getReminder(reminderId);

    if (updated != null) {
      await _schedule(updated, task);
    }
  }

  Future<void> cancelScheduledForTask(String taskId) async {
    final reminders = await _enabledForTask(taskId);

    for (final reminder in reminders) {
      await _notifications.cancel(reminder.notificationId);
    }
  }

  Future<void> rescheduleAllFuture() async {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNull() &
            task.status
                .equalsValue(
                  TaskStatus.completed,
                )
                .not() &
            task.status
                .equalsValue(
                  TaskStatus.cancelled,
                )
                .not(),
      );

    final tasks = await query.get();

    for (final task in tasks) {
      await rescheduleFutureForTask(
        task.id,
      );
    }
  }

  Future<void> rescheduleFutureForTask(String taskId) async {
    final task = await _getTask(taskId);

    if (task == null ||
        task.deletedAt != null ||
        task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      await cancelScheduledForTask(taskId);
      return;
    }

    final reminders = await _enabledForTask(taskId);

    for (final reminder in reminders) {
      if (reminder.kind == ReminderKind.relativeToDue &&
          (task.dueAt == null || !task.hasDueTime)) {
        await _notifications.cancel(reminder.notificationId);
        continue;
      }

      final effectiveAt = reminder.snoozedUntil ?? reminder.scheduledAt;

      if (!effectiveAt.isAfter(DateTime.now())) {
        await _notifications.cancel(reminder.notificationId);
        continue;
      }

      await _schedule(reminder, task);
    }
  }

  Future<void> recalculateRelativeAndReschedule(String taskId) async {
    final task = await _getTask(taskId);

    if (task == null) {
      return;
    }

    final reminders = await _enabledForTask(taskId);

    for (final reminder in reminders) {
      if (reminder.kind != ReminderKind.relativeToDue) {
        continue;
      }

      if (task.dueAt == null || !task.hasDueTime) {
        await _notifications.cancel(reminder.notificationId);
        continue;
      }

      final offset = reminder.offsetMinutes ?? 0;
      final nextTime = task.dueAt!.subtract(
        Duration(minutes: offset),
      );

      await (_db.update(_db.reminders)
            ..where((row) => row.id.equals(reminder.id)))
          .write(
        RemindersCompanion(
          scheduledAt: Value(nextTime),
          snoozedUntil: const Value(null),
        ),
      );
    }

    await rescheduleFutureForTask(taskId);
  }

  Future<void> _schedule(
    Reminder reminder,
    Task task,
  ) async {
    final effectiveAt = reminder.snoozedUntil ?? reminder.scheduledAt;

    if (!effectiveAt.isAfter(DateTime.now())) {
      await _notifications.cancel(reminder.notificationId);
      return;
    }

    await _notifications.schedule(
      notificationId: reminder.notificationId,
      title: task.title,
      body: _notificationBody(reminder),
      scheduledAt: effectiveAt,
      payload: NotificationPayload(
        taskId: task.id,
        reminderId: reminder.id,
      ),
    );
  }

  String _notificationBody(Reminder reminder) {
    if (reminder.snoozedUntil != null) {
      return 'Snoozed task reminder';
    }

    return switch (reminder.kind) {
      ReminderKind.absolute => 'Task reminder',
      ReminderKind.relativeToDue =>
        _relativeDescription(reminder.offsetMinutes ?? 0),
    };
  }

  String _relativeDescription(int minutes) {
    if (minutes == 0) {
      return 'Due now';
    }

    if (minutes == 60) {
      return 'Due in 1 hour';
    }

    if (minutes == 1440) {
      return 'Due in 1 day';
    }

    if (minutes < 60) {
      return 'Due in $minutes minutes';
    }

    return 'Upcoming task';
  }

  Future<Task?> _getTask(String taskId) {
    final query = _db.select(_db.tasks)
      ..where((task) => task.id.equals(taskId));

    return query.getSingleOrNull();
  }

  Future<Reminder?> _getReminder(String reminderId) {
    final query = _db.select(_db.reminders)
      ..where((reminder) => reminder.id.equals(reminderId));

    return query.getSingleOrNull();
  }

  Future<List<Reminder>> _enabledForTask(String taskId) {
    final query = _db.select(_db.reminders)
      ..where(
        (reminder) =>
            reminder.taskId.equals(taskId) & reminder.isEnabled.equals(true),
      );

    return query.get();
  }

  Future<int> _allocateNotificationId() async {
    for (var i = 0; i < 20; i++) {
      final candidate =
          100000 + _random.nextInt(0x7fffffff - 100000);

      final existing = await (_db.select(_db.reminders)
            ..where(
              (reminder) => reminder.notificationId.equals(candidate),
            ))
          .getSingleOrNull();

      if (existing == null) {
        return candidate;
      }
    }

    throw StateError('Could not allocate notification id.');
  }

  void _requireFuture(DateTime date) {
    if (!date.isAfter(DateTime.now())) {
      throw ArgumentError('Reminder must be in the future.');
    }
  }
}
