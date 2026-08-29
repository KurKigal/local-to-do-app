import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/recurrences.dart';
import '../../../core/database/tables/reminders.dart';
import '../../../core/database/tables/tasks.dart';
import 'reminder_repository.dart';

class RecurrenceService {
  RecurrenceService({
    required AppDatabase database,
    required ReminderRepository reminders,
  })  : _db = database,
        _reminders = reminders;

  final AppDatabase _db;
  final ReminderRepository _reminders;

  static const _uuid = Uuid();

  Future<String?> generateNextOccurrence(
    String taskId,
  ) async {
    final task = await _getTask(taskId);
    final recurrence =
        await _getRecurrence(taskId);

    if (task == null ||
        recurrence == null ||
        task.dueAt == null) {
      return null;
    }

    if (recurrence.nextOccurrenceTaskId !=
        null) {
      return recurrence
          .nextOccurrenceTaskId;
    }

    final next =
        _firstFutureOccurrence(
      current: task.dueAt!,
      recurrence: recurrence,
      now: DateTime.now(),
    );

    if (next == null) {
      return null;
    }

    final nextOccurrenceNumber =
        recurrence.occurrenceNumber +
            next.steps;

    final maxOccurrences =
        recurrence.maxOccurrences;

    if (maxOccurrences != null &&
        nextOccurrenceNumber >
            maxOccurrences) {
      return null;
    }

    if (recurrence.endAt != null &&
        next.date.isAfter(
          recurrence.endAt!,
        )) {
      return null;
    }

    final newTaskId = _uuid.v4();
    final newRecurrenceId =
        _uuid.v4();
    final now = DateTime.now();

    final shift =
        next.date.difference(
      task.dueAt!,
    );

    final subtasks = await (_db.select(
      _db.subtasks,
    )
          ..where(
            (subtask) =>
                subtask.taskId.equals(
                  task.id,
                ),
          )
          ..orderBy([
            (subtask) =>
                OrderingTerm.asc(
                  subtask.sortOrder,
                ),
          ]))
        .get();

    final taskTags = await (_db.select(
      _db.taskTags,
    )
          ..where(
            (taskTag) =>
                taskTag.taskId.equals(
                  task.id,
                ),
          ))
        .get();

    final relativeReminders =
        await (_db.select(
      _db.reminders,
    )
              ..where(
                (reminder) =>
                    reminder.taskId
                        .equals(task.id) &
                    reminder.isEnabled
                        .equals(true) &
                    reminder.kind.equalsValue(
                      ReminderKind
                          .relativeToDue,
                    ),
              ))
            .get();

    await _db.transaction(() async {
      await _db.into(_db.tasks).insert(
            TasksCompanion.insert(
              id: newTaskId,
              projectId:
                  Value(task.projectId),
              title: task.title,
              description:
                  Value(task.description),
              status: TaskStatus.todo,
              priority: task.priority,
              startAt: Value(
                task.startAt?.add(shift),
              ),
              dueAt: Value(next.date),
              hasDueTime: Value(
                task.hasDueTime,
              ),
              sortOrder: Value(
                now.microsecondsSinceEpoch
                    .toDouble(),
              ),
              createdAt: now,
              updatedAt: now,
            ),
          );

      if (taskTags.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.taskTags,
            [
              for (final taskTag
                  in taskTags)
                TaskTagsCompanion.insert(
                  taskId: newTaskId,
                  tagId: taskTag.tagId,
                ),
            ],
          );
        });
      }

      if (subtasks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.subtasks,
            [
              for (final subtask
                  in subtasks)
                SubtasksCompanion.insert(
                  id: _uuid.v4(),
                  taskId: newTaskId,
                  title: subtask.title,
                  sortOrder: Value(
                    subtask.sortOrder,
                  ),
                  createdAt: now,
                ),
            ],
          );
        });
      }

      await _db
          .into(_db.recurrences)
          .insert(
            RecurrencesCompanion.insert(
              id: newRecurrenceId,
              taskId: newTaskId,
              frequency:
                  recurrence.frequency,
              interval: Value(
                recurrence.interval,
              ),
              weekdays: Value(
                recurrence.weekdays,
              ),
              endAt: Value(
                recurrence.endAt,
              ),
              maxOccurrences: Value(
                recurrence
                    .maxOccurrences,
              ),
              occurrenceNumber: Value(
                nextOccurrenceNumber,
              ),
            ),
          );

      await (_db.update(
        _db.recurrences,
      )
            ..where(
              (row) =>
                  row.id.equals(
                    recurrence.id,
                  ),
            ))
          .write(
        RecurrencesCompanion(
          nextOccurrenceTaskId:
              Value(newTaskId),
        ),
      );
    });

    // Absolute reminders belong to a specific occurrence.
    // Only relative reminders are recreated for the new due time.
    for (final reminder
        in relativeReminders) {
      try {
        await _reminders.createRelative(
          taskId: newTaskId,
          minutesBeforeDue:
              reminder.offsetMinutes ?? 0,
        );
      } catch (_) {
        // A very large offset could already be in the past.
        // The new task should still be created successfully.
      }
    }

    return newTaskId;
  }

  Future<Task?> _getTask(
    String taskId,
  ) {
    final query = _db.select(_db.tasks)
      ..where(
        (task) => task.id.equals(taskId),
      );

    return query.getSingleOrNull();
  }

  Future<Recurrence?> _getRecurrence(
    String taskId,
  ) {
    final query =
        _db.select(_db.recurrences)
          ..where(
            (recurrence) =>
                recurrence.taskId
                    .equals(taskId),
          );

    return query.getSingleOrNull();
  }

  _NextOccurrence?
      _firstFutureOccurrence({
    required DateTime current,
    required Recurrence recurrence,
    required DateTime now,
  }) {
    var candidate = current;
    var steps = 0;

    for (var i = 0; i < 10000; i++) {
      candidate = _nextOccurrence(
        candidate,
        recurrence,
      );

      steps++;

      final occurrenceNumber =
          recurrence.occurrenceNumber +
              steps;

      if (recurrence
                  .maxOccurrences !=
              null &&
          occurrenceNumber >
              recurrence.maxOccurrences!) {
        return null;
      }

      if (recurrence.endAt != null &&
          candidate.isAfter(
            recurrence.endAt!,
          )) {
        return null;
      }

      if (candidate.isAfter(now)) {
        return _NextOccurrence(
          date: candidate,
          steps: steps,
        );
      }
    }

    throw StateError(
      'Recurrence calculation exceeded safety limit.',
    );
  }

  DateTime _nextOccurrence(
    DateTime current,
    Recurrence recurrence,
  ) {
    final interval =
        max(1, recurrence.interval);

    return switch (
        recurrence.frequency) {
      RecurrenceFrequency.daily =>
        _addCalendarDays(
          current,
          interval,
        ),
      RecurrenceFrequency.weekly =>
        _nextWeekly(
          current,
          interval,
          _decodeWeekdays(
            recurrence.weekdays,
          ),
        ),
      RecurrenceFrequency.monthly =>
        _addMonths(
          current,
          interval,
        ),
      RecurrenceFrequency.yearly =>
        _addYears(
          current,
          interval,
        ),
    };
  }

  DateTime _nextWeekly(
    DateTime current,
    int interval,
    Set<int> weekdays,
  ) {
    if (weekdays.isEmpty) {
      return _addCalendarDays(
        current,
        7 * interval,
      );
    }

    final sorted =
        weekdays.toList()..sort();

    for (final weekday in sorted) {
      if (weekday >
          current.weekday) {
        return _addCalendarDays(
          current,
          weekday -
              current.weekday,
        );
      }
    }

    final first =
        sorted.first;

    final days =
        (7 * interval) -
            current.weekday +
            first;

    return _addCalendarDays(
      current,
      days,
    );
  }

  DateTime _addCalendarDays(
    DateTime value,
    int days,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day + days,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  DateTime _addMonths(
    DateTime value,
    int months,
  ) {
    final rawMonth =
        value.month - 1 + months;

    final year =
        value.year +
            rawMonth ~/ 12;

    final month =
        rawMonth % 12 + 1;

    final day = min(
      value.day,
      _daysInMonth(
        year,
        month,
      ),
    );

    return DateTime(
      year,
      month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  DateTime _addYears(
    DateTime value,
    int years,
  ) {
    final year =
        value.year + years;

    final day = min(
      value.day,
      _daysInMonth(
        year,
        value.month,
      ),
    );

    return DateTime(
      year,
      value.month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }

  int _daysInMonth(
    int year,
    int month,
  ) {
    return DateTime(
      year,
      month + 1,
      0,
    ).day;
  }

  Set<int> _decodeWeekdays(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(value);

      if (decoded is! List) {
        return {};
      }

      return decoded
          .whereType<num>()
          .map((value) => value.toInt())
          .where(
            (day) => day >= 1 && day <= 7,
          )
          .toSet();
    } catch (_) {
      return {};
    }
  }
}

class _NextOccurrence {
  const _NextOccurrence({
    required this.date,
    required this.steps,
  });

  final DateTime date;
  final int steps;
}
