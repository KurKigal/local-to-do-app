import 'package:image_picker/image_picker.dart';

import '../../features/tasks/data/attachment_import_service.dart';
import '../database/app_database.dart';
import 'attachment_storage.dart';
import 'pending_attachment_picker.dart';

abstract final class AttachmentLostDataRecovery {
  static Future<int> run() async {
    final taskId =
        await PendingAttachmentPicker
            .taskId();

    if (taskId == null) {
      return 0;
    }

    try {
      final response =
          await ImagePicker()
              .retrieveLostData();

      if (response.isEmpty) {
        return 0;
      }

      final files = <XFile>[
        ...?response.files,
        if (response.files == null &&
            response.file != null)
          response.file!,
      ];

      if (files.isEmpty) {
        return 0;
      }

      final database =
          AppDatabase();

      try {
        final importer =
            AttachmentImportService(
          database: database,
          storage:
              AttachmentStorage(),
        );

        var recovered = 0;

        for (final file in files) {
          try {
            await importer.import(
              taskId: taskId,
              source: file,
            );

            recovered++;
          } catch (_) {
            // Recovery is best effort. A single bad picker
            // result must not stop app startup.
          }
        }

        return recovered;
      } finally {
        await database.close();
      }
    } catch (_) {
      return 0;
    } finally {
      await PendingAttachmentPicker
          .clear();
    }
  }
}
