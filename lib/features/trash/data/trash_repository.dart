import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class TrashRepository {
  TrashRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchTrash() {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNotNull(),
      )
      ..orderBy([
        (task) => OrderingTerm.desc(
              task.deletedAt,
            ),
      ]);

    return query.watch();
  }

  Future<List<Task>> getTrash() {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.deletedAt.isNotNull(),
      )
      ..orderBy([
        (task) => OrderingTerm.desc(
              task.deletedAt,
            ),
      ]);

    return query.get();
  }

  Future<Task?> getTask(
    String taskId,
  ) {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.id.equals(taskId),
      );

    return query.getSingleOrNull();
  }

  Future<List<Attachment>>
      getAttachments(
    String taskId,
  ) {
    final query =
        _db.select(_db.attachments)
          ..where(
            (attachment) =>
                attachment.taskId
                    .equals(taskId),
          );

    return query.get();
  }

  Future<void> restoreRow(
    String taskId,
  ) async {
    await (_db.update(_db.tasks)
          ..where(
            (task) =>
                task.id.equals(taskId),
          ))
        .write(
      TasksCompanion(
        deletedAt:
            const Value(null),
        updatedAt:
            Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteForeverRow(
    String taskId,
  ) async {
    await (_db.delete(_db.tasks)
          ..where(
            (task) =>
                task.id.equals(taskId),
          ))
        .go();
  }

  Future<Set<String>>
      getAllExistingTaskIds() async {
    final query =
        _db.selectOnly(_db.tasks)
          ..addColumns([
            _db.tasks.id,
          ]);

    final result =
        await query.get();

    return result
        .map(
          (row) =>
              row.read(_db.tasks.id),
        )
        .whereType<String>()
        .toSet();
  }
}
