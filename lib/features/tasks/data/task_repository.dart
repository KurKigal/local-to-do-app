import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks.dart';
import '../../../core/utils/date_time_utils.dart';


class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------

  Future<String> createTask({
    required String title,
    String? description,
    String? projectId,
    TaskPriority priority = TaskPriority.none,
    DateTime? dueAt,
    bool hasDueTime = false,
  }) async {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: id,
            title: trimmedTitle,
            description: Value(
              _normalizeOptionalText(description),
            ),
            projectId: Value(projectId),
            status: TaskStatus.todo,
            priority: priority,
            dueAt: Value(dueAt),
            hasDueTime: Value(hasDueTime),
            sortOrder: Value(
              now.microsecondsSinceEpoch.toDouble(),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  Stream<Task?> watchTask(String id) {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.id.equals(id) &
            task.deletedAt.isNull(),
      );

    return query.watchSingleOrNull();
  }

  Future<Task?> getTask(String id) {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.id.equals(id) &
            task.deletedAt.isNull(),
      );

    return query.getSingleOrNull();
  }

  Stream<List<Task>> watchToday() {
    final now = DateTime.now();

    final start = startOfDay(now);
    final tomorrow = startOfNextDay(now);

    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNull() &
            task.status
                .equalsValue(TaskStatus.completed)
                .not() &
            task.status
                .equalsValue(TaskStatus.cancelled)
                .not() &
            task.dueAt.isNotNull() &
            task.dueAt.isBiggerOrEqualValue(start) &
            task.dueAt.isSmallerThanValue(tomorrow),
      )
      ..orderBy([
        (task) => OrderingTerm.asc(task.dueAt),
        (task) => OrderingTerm.asc(task.sortOrder),
      ]);

    return query.watch();
  }

  Stream<List<Task>> watchOverdue() {
    final today = startOfDay(DateTime.now());

    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNull() &
            task.status
                .equalsValue(TaskStatus.completed)
                .not() &
            task.status
                .equalsValue(TaskStatus.cancelled)
                .not() &
            task.dueAt.isNotNull() &
            task.dueAt.isSmallerThanValue(today),
      )
      ..orderBy([
        (task) => OrderingTerm.asc(task.dueAt),
      ]);

    return query.watch();
  }

  Stream<List<Task>> watchAllActive() {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNull() &
            task.status
                .equalsValue(TaskStatus.cancelled)
                .not(),
      )
      ..orderBy([
        (task) => OrderingTerm.asc(task.dueAt),
        (task) => OrderingTerm.asc(task.sortOrder),
      ]);

    return query.watch();
  }

  Stream<List<Task>> watchCompleted() {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNull() &
            task.status.equalsValue(
              TaskStatus.completed,
            ),
      )
      ..orderBy([
        (task) => OrderingTerm.desc(
              task.completedAt,
            ),
      ]);

    return query.watch();
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------

  Future<void> updateTask({
    required String id,
    required String title,
    String? description,
    String? projectId,
    required TaskPriority priority,
    DateTime? dueAt,
    required bool hasDueTime,
  }) async {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }

    await (_db.update(_db.tasks)
          ..where((task) => task.id.equals(id)))
        .write(
      TasksCompanion(
        title: Value(trimmedTitle),
        description: Value(
          _normalizeOptionalText(description),
        ),
        projectId: Value(projectId),
        priority: Value(priority),
        dueAt: Value(dueAt),
        hasDueTime: Value(hasDueTime),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> setCompleted(
    String id, {
    required bool completed,
  }) async {
    final now = DateTime.now();

    await (_db.update(_db.tasks)
          ..where((task) => task.id.equals(id)))
        .write(
      TasksCompanion(
        status: Value(
          completed
              ? TaskStatus.completed
              : TaskStatus.todo,
        ),
        completedAt: Value(
          completed ? now : null,
        ),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> changePriority(
    String id,
    TaskPriority priority,
  ) async {
    await (_db.update(_db.tasks)
          ..where((task) => task.id.equals(id)))
        .write(
      TasksCompanion(
        priority: Value(priority),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> moveToTrash(String id) async {
    final now = DateTime.now();

    await (_db.update(_db.tasks)
          ..where((task) => task.id.equals(id)))
        .write(
      TasksCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> restore(String id) async {
    await (_db.update(_db.tasks)
          ..where((task) => task.id.equals(id)))
        .write(
      TasksCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}