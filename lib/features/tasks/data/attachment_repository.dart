import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/storage/attachment_storage.dart';

class AttachmentRepository {
  AttachmentRepository({
    required AppDatabase database,
    required AttachmentStorage storage,
  })  : _db = database,
        _storage = storage;

  final AppDatabase _db;
  final AttachmentStorage _storage;

  static const _uuid = Uuid();

  Stream<List<Attachment>> watchForTask(
    String taskId,
  ) {
    final query = _db.select(_db.attachments)
      ..where(
        (attachment) =>
            attachment.taskId.equals(taskId),
      )
      ..orderBy([
        (attachment) =>
            OrderingTerm.asc(attachment.createdAt),
      ]);

    return query.watch();
  }

  Future<String> add({
    required String taskId,
    required XFile source,
  }) async {
    final imported = await _storage.importFile(
      taskId: taskId,
      source: source,
    );

    final id = _uuid.v4();

    try {
      await _db.into(_db.attachments).insert(
            AttachmentsCompanion.insert(
              id: id,
              taskId: taskId,
              type: imported.type,
              relativePath:
                  imported.relativePath,
              originalName:
                  imported.originalName,
              mimeType: Value(
                imported.mimeType,
              ),
              size: imported.size,
              createdAt: DateTime.now(),
            ),
          );

      return id;
    } catch (_) {
      // DB insert başarısız olduysa orphan
      // dosya bırakmayalım.
      await _storage.delete(
        imported.relativePath,
      );

      rethrow;
    }
  }

  Future<File> resolveFile(
    Attachment attachment,
  ) {
    return _storage.resolve(
      attachment.relativePath,
    );
  }

  Future<void> delete(
    String attachmentId,
  ) async {
    final query = _db.select(_db.attachments)
      ..where(
        (attachment) =>
            attachment.id.equals(attachmentId),
      );

    final attachment =
        await query.getSingleOrNull();

    if (attachment == null) {
      return;
    }

    await (_db.delete(_db.attachments)
          ..where(
            (row) =>
                row.id.equals(attachmentId),
          ))
        .go();

    try {
      await _storage.delete(
        attachment.relativePath,
      );
    } catch (_) {
      // DB doğru durumda.
      // Orphan file ileride storage cleanup ile
      // temizlenebilir.
    }
  }
}