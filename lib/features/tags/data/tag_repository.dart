import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Stream<List<Tag>> watchAll() {
    final query =
        _db.select(_db.tags)
          ..orderBy([
            (tag) =>
                OrderingTerm.asc(
                  tag.name,
                ),
          ]);

    return query.watch();
  }

  Stream<List<Tag>> watchForTask(
    String taskId,
  ) {
    final query =
        _db.select(_db.tags).join([
      innerJoin(
        _db.taskTags,
        _db.taskTags.tagId.equalsExp(
          _db.tags.id,
        ),
      ),
    ])
          ..where(
            _db.taskTags.taskId
                .equals(taskId),
          )
          ..orderBy([
            OrderingTerm.asc(
              _db.tags.name,
            ),
          ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => row.readTable(
                  _db.tags,
                ),
              )
              .toList(),
        );
  }

  Future<List<Tag>> getForTask(
    String taskId,
  ) {
    final query =
        _db.select(_db.tags).join([
      innerJoin(
        _db.taskTags,
        _db.taskTags.tagId.equalsExp(
          _db.tags.id,
        ),
      ),
    ])
          ..where(
            _db.taskTags.taskId
                .equals(taskId),
          )
          ..orderBy([
            OrderingTerm.asc(
              _db.tags.name,
            ),
          ]);

    return query.get().then(
          (rows) => rows
              .map(
                (row) => row.readTable(
                  _db.tags,
                ),
              )
              .toList(),
        );
  }

  Future<String> create({
    required String name,
    int? color,
  }) async {
    final normalized =
        name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Tag name cannot be empty.',
      );
    }

    final existing =
        await (_db.select(_db.tags)
              ..where(
                (tag) =>
                    tag.name.equals(
                  normalized,
                ),
              ))
            .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    final id = _uuid.v4();

    await _db.into(_db.tags).insert(
          TagsCompanion.insert(
            id: id,
            name: normalized,
            color: Value(color),
            createdAt:
                DateTime.now(),
          ),
        );

    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    int? color,
  }) async {
    final normalized =
        name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Tag name cannot be empty.',
      );
    }

    final duplicate =
        await (_db.select(_db.tags)
              ..where(
                (tag) =>
                    tag.name.equals(
                      normalized,
                    ) &
                    tag.id
                        .equals(id)
                        .not(),
              ))
            .getSingleOrNull();

    if (duplicate != null) {
      throw StateError(
        'A tag with this name already exists.',
      );
    }

    await (_db.update(_db.tags)
          ..where(
            (tag) =>
                tag.id.equals(id),
          ))
        .write(
      TagsCompanion(
        name: Value(normalized),
        color: Value(color),
      ),
    );
  }

  Future<void> setTagsForTask(
    String taskId,
    Set<String> tagIds,
  ) async {
    await _db.transaction(
      () async {
        await (_db.delete(
          _db.taskTags,
        )
              ..where(
                (row) =>
                    row.taskId.equals(
                  taskId,
                ),
              ))
            .go();

        if (tagIds.isEmpty) {
          return;
        }

        await _db.batch(
          (batch) {
            batch.insertAll(
              _db.taskTags,
              [
                for (final tagId
                    in tagIds)
                  TaskTagsCompanion
                      .insert(
                    taskId: taskId,
                    tagId: tagId,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> delete(
    String tagId,
  ) async {
    await (_db.delete(_db.tags)
          ..where(
            (tag) =>
                tag.id.equals(tagId),
          ))
        .go();
  }
}
