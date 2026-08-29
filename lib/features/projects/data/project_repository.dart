import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks.dart';

class ProjectRepository {
  ProjectRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Stream<List<Project>> watchAll() {
    final query = _db.select(_db.projects)
      ..where(
        (project) => project.deletedAt.isNull(),
      )
      ..orderBy([
        (project) => OrderingTerm.asc(project.sortOrder),
        (project) => OrderingTerm.asc(project.name),
      ]);

    return query.watch();
  }

  Stream<Project?> watchById(String projectId) {
    final query = _db.select(_db.projects)
      ..where(
        (project) =>
            project.id.equals(projectId) &
            project.deletedAt.isNull(),
      );

    return query.watchSingleOrNull();
  }

  Stream<List<Task>> watchTasks(String projectId) {
    final query = _db.select(_db.tasks)
      ..where(
        (task) =>
            task.projectId.equals(projectId) &
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

  Future<String> create({
    required String name,
    String icon = 'folder',
    int? color,
  }) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.into(_db.projects).insert(
          ProjectsCompanion.insert(
            id: id,
            name: normalized,
            icon: Value(icon),
            color: Value(color),
            sortOrder: Value(
              now.microsecondsSinceEpoch.toDouble(),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    String? icon,
    int? color,
  }) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('Project name cannot be empty.');
    }

    await (_db.update(_db.projects)
          ..where((project) => project.id.equals(id)))
        .write(
      ProjectsCompanion(
        name: Value(normalized),
        icon: Value(icon),
        color: Value(color),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String projectId) async {
    final now = DateTime.now();

    await _db.transaction(() async {
      await (_db.update(_db.tasks)
            ..where(
              (task) => task.projectId.equals(projectId),
            ))
          .write(
        TasksCompanion(
          projectId: const Value(null),
          updatedAt: Value(now),
        ),
      );

      await (_db.update(_db.projects)
            ..where(
              (project) => project.id.equals(projectId),
            ))
          .write(
        ProjectsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }
}
