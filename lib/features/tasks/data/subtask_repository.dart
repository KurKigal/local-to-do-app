import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class SubtaskRepository {
  SubtaskRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Stream<List<Subtask>> watchForTask(
    String taskId,
  ) {
    final query = _db.select(_db.subtasks)
      ..where(
        (subtask) => subtask.taskId.equals(taskId),
      )
      ..orderBy([
        (subtask) =>
            OrderingTerm.asc(subtask.sortOrder),
      ]);

    return query.watch();
  }

  Future<String> create({
    required String taskId,
    required String title,
  }) async {
    final normalized = title.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Subtask title cannot be empty.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.subtasks).insert(
          SubtasksCompanion.insert(
            id: id,
            taskId: taskId,
            title: normalized,
            sortOrder: Value(
              now.microsecondsSinceEpoch.toDouble(),
            ),
            createdAt: now,
          ),
        );

    return id;
  }

  Future<void> setCompleted(
    String id, {
    required bool completed,
  }) async {
    await (_db.update(_db.subtasks)
          ..where(
            (subtask) => subtask.id.equals(id),
          ))
        .write(
      SubtasksCompanion(
        isCompleted: Value(completed),
        completedAt: Value(
          completed ? DateTime.now() : null,
        ),
      ),
    );
  }

  Future<void> updateTitle(
    String id,
    String title,
  ) async {
    final normalized = title.trim();

    if (normalized.isEmpty) {
      return;
    }

    await (_db.update(_db.subtasks)
          ..where(
            (subtask) => subtask.id.equals(id),
          ))
        .write(
      SubtasksCompanion(
        title: Value(normalized),
      ),
    );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.subtasks)
          ..where(
            (subtask) => subtask.id.equals(id),
          ))
        .go();
  }
}