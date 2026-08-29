import 'package:cross_file/cross_file.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/storage/attachment_storage.dart';

class AttachmentImportService {
  AttachmentImportService({
    required AppDatabase database,
    required AttachmentStorage storage,
  })  : _database = database,
        _storage = storage;

  final AppDatabase _database;
  final AttachmentStorage _storage;

  static const _uuid = Uuid();

  Future<Attachment> import({
    required String taskId,
    required XFile source,
  }) async {
    final task =
        await (_database.select(
      _database.tasks,
    )
              ..where(
                (task) =>
                    task.id.equals(taskId) &
                    task.deletedAt.isNull(),
              ))
            .getSingleOrNull();

    if (task == null) {
      throw StateError(
        'The target task no longer exists.',
      );
    }

    final imported =
        await _storage.importFile(
      taskId: taskId,
      source: source,
    );

    final id = _uuid.v4();

    try {
      await _database
          .into(_database.attachments)
          .insert(
            AttachmentsCompanion.insert(
              id: id,
              taskId: taskId,
              type: imported.type,
              relativePath:
                  imported.relativePath,
              originalName:
                  imported.originalName,
              mimeType:
                  Value(imported.mimeType),
              size: imported.size,
              createdAt: DateTime.now(),
            ),
          );
    } catch (_) {
      try {
        await _storage.delete(
          imported.relativePath,
        );
      } catch (_) {}

      rethrow;
    }

    final attachment =
        await (_database.select(
      _database.attachments,
    )
              ..where(
                (row) =>
                    row.id.equals(id),
              ))
            .getSingle();

    return attachment;
  }
}
