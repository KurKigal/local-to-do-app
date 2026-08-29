import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../database/tables/attachments.dart';

class ImportedAttachment {
  const ImportedAttachment({
    required this.relativePath,
    required this.originalName,
    required this.size,
    required this.type,
    this.mimeType,
  });

  final String relativePath;
  final String originalName;
  final int size;
  final String? mimeType;
  final AttachmentType type;
}

class AttachmentStorage {
  static const _uuid = Uuid();

  Future<ImportedAttachment> importFile({
    required String taskId,
    required XFile source,
  }) async {
    final root = await rootDirectory();

    final taskDirectory = Directory(
      p.join(
        root.path,
        taskId,
      ),
    );

    if (!await taskDirectory.exists()) {
      await taskDirectory.create(
        recursive: true,
      );
    }

    final originalName = source.name.isNotEmpty
        ? source.name
        : 'attachment';

    final extension =
        p.extension(originalName);

    final storedName =
        '${_uuid.v4()}$extension';

    final target = File(
      p.join(
        taskDirectory.path,
        storedName,
      ),
    );

    await source.saveTo(target.path);

    final size = await target.length();

    final mimeType =
        source.mimeType ??
            lookupMimeType(
              originalName,
            );

    final type =
        _attachmentTypeFromMime(
      mimeType,
    );

    final relativePath = p.join(
      'attachments',
      taskId,
      storedName,
    );

    return ImportedAttachment(
      relativePath: relativePath,
      originalName: originalName,
      size: size,
      mimeType: mimeType,
      type: type,
    );
  }

  Future<File> resolve(
    String relativePath,
  ) async {
    final documents =
        await getApplicationDocumentsDirectory();

    return File(
      p.join(
        documents.path,
        relativePath,
      ),
    );
  }

  Future<void> delete(
    String relativePath,
  ) async {
    final file =
        await resolve(relativePath);

    if (await file.exists()) {
      await file.delete();
    }

    final parent = file.parent;

    if (await parent.exists()) {
      final isEmpty =
          await parent.list().isEmpty;

      if (isEmpty) {
        await parent.delete();
      }
    }
  }

  /// Removes the entire app-private attachment directory for a task.
  ///
  /// This is only intended for permanent task deletion.
  Future<void> deleteTaskDirectory(
    String taskId,
  ) async {
    final documents =
        await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(
        documents.path,
        'attachments',
        taskId,
      ),
    );

    if (await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }

  /// Best-effort cleanup for directories that no longer belong to a task.
  ///
  /// Returns the number of directories removed.
  Future<int> cleanupOrphanTaskDirectories({
    required Set<String> validTaskIds,
  }) async {
    final root = await rootDirectory();

    var removed = 0;

    await for (final entity
        in root.list()) {
      if (entity is! Directory) {
        continue;
      }

      final taskId =
          p.basename(entity.path);

      if (validTaskIds.contains(
        taskId,
      )) {
        continue;
      }

      try {
        await entity.delete(
          recursive: true,
        );

        removed++;
      } catch (_) {
        // Best effort. A later cleanup can retry.
      }
    }

    return removed;
  }

  Future<Directory>
      rootDirectory() async {
    final documents =
        await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(
        documents.path,
        'attachments',
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  AttachmentType
      _attachmentTypeFromMime(
    String? mime,
  ) {
    if (mime?.startsWith('image/') ==
        true) {
      return AttachmentType.image;
    }

    if (mime?.startsWith('video/') ==
        true) {
      return AttachmentType.video;
    }

    return AttachmentType.file;
  }
}
