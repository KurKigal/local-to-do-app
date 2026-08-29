import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/storage/pending_attachment_picker.dart';
import '../../data/attachment_import_service.dart';
import '../../providers/task_providers.dart';

Future<void> showAddAttachmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String taskId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return _AddAttachmentSheet(
        taskId: taskId,
      );
    },
  );
}

class _AddAttachmentSheet
    extends ConsumerStatefulWidget {
  const _AddAttachmentSheet({
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<_AddAttachmentSheet>
      createState() =>
          _AddAttachmentSheetState();
}

class _AddAttachmentSheetState
    extends ConsumerState<_AddAttachmentSheet> {
  bool _busy = false;

  AttachmentImportService get _importer =>
      AttachmentImportService(
        database: ref.read(
          databaseProvider,
        ),
        storage: ref.read(
          attachmentStorageProvider,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: !_busy,
              leading: const Icon(
                Icons.photo_camera_outlined,
              ),
              title: const Text(
                'Take photo',
              ),
              onTap: () => _pickImage(
                ImageSource.camera,
              ),
            ),
            ListTile(
              enabled: !_busy,
              leading: const Icon(
                Icons.photo_library_outlined,
              ),
              title: const Text(
                'Choose photo',
              ),
              onTap: () => _pickImage(
                ImageSource.gallery,
              ),
            ),
            ListTile(
              enabled: !_busy,
              leading: const Icon(
                Icons.videocam_outlined,
              ),
              title: const Text(
                'Choose video',
              ),
              onTap: () => _pickVideo(
                ImageSource.gallery,
              ),
            ),
            ListTile(
              enabled: !_busy,
              leading: const Icon(
                Icons.video_call_outlined,
              ),
              title: const Text(
                'Record video',
              ),
              onTap: () => _pickVideo(
                ImageSource.camera,
              ),
            ),
            ListTile(
              enabled: !_busy,
              leading: const Icon(
                Icons.attach_file_rounded,
              ),
              title: const Text(
                'Choose file',
              ),
              onTap: _pickFile,
            ),
            if (_busy) ...[
              const SizedBox(height: 4),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
  ) async {
    await _runImagePicker(
      () => ImagePicker().pickImage(
        source: source,
      ),
    );
  }

  Future<void> _pickVideo(
    ImageSource source,
  ) async {
    await _runImagePicker(
      () => ImagePicker().pickVideo(
        source: source,
      ),
    );
  }

  Future<void> _runImagePicker(
    Future<XFile?> Function() picker,
  ) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    await PendingAttachmentPicker.begin(
      widget.taskId,
    );

    try {
      final file = await picker();

      if (file == null) {
        return;
      }

      await _importer.import(
        taskId: widget.taskId,
        source: file,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      await PendingAttachmentPicker.clear();

      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final result =
          await FilePicker.pickFiles(
        allowMultiple: false,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final picked =
          result.files.single;

      final path = picked.path;

      if (path == null) {
        throw StateError(
          'Could not access the selected file.',
        );
      }

      await _importer.import(
        taskId: widget.taskId,
        source: XFile(
          path,
          name: picked.name,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _showError(
    Object error,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Could not add attachment: $error',
        ),
      ),
    );
  }
}
