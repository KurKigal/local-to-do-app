import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import 'attachment_repository.dart';

class AttachmentOpenResult {
  const AttachmentOpenResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}

class AttachmentActionService {
  AttachmentActionService(
    this._repository,
  );

  final AttachmentRepository _repository;

  Future<AttachmentOpenResult> openExternal(
    Attachment attachment,
  ) async {
    final file =
        await _repository.resolveFile(
      attachment,
    );

    if (!await file.exists()) {
      return const AttachmentOpenResult(
        success: false,
        message:
            'The attachment file no longer exists.',
      );
    }

    final result =
        await OpenFilex.open(
      file.path,
      type: attachment.mimeType,
    );

    if (result.type ==
        ResultType.done) {
      return const AttachmentOpenResult(
        success: true,
      );
    }

    return AttachmentOpenResult(
      success: false,
      message: result.message.isEmpty
          ? 'No compatible app could open this file.'
          : result.message,
    );
  }

  Future<void> share(
    Attachment attachment,
  ) async {
    final file =
        await _repository.resolveFile(
      attachment,
    );

    if (!await file.exists()) {
      throw StateError(
        'The attachment file no longer exists.',
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        title: attachment.originalName,
        files: [
          XFile(
            file.path,
            name: attachment.originalName,
            mimeType:
                attachment.mimeType,
          ),
        ],
        fileNameOverrides: [
          attachment.originalName,
        ],
      ),
    );
  }
}
