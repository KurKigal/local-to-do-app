import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../backup/providers/backup_providers.dart';
import '../../../trash/providers/trash_providers.dart';

class DataStorageSection
    extends ConsumerStatefulWidget {
  const DataStorageSection({
    super.key,
  });

  @override
  ConsumerState<DataStorageSection>
      createState() =>
          _DataStorageSectionState();
}

class _DataStorageSectionState
    extends ConsumerState<
        DataStorageSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final usage =
        ref.watch(storageUsageProvider);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Data & Storage',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.save_alt_rounded,
                ),
                title: const Text(
                  'Create backup',
                ),
                subtitle: const Text(
                  'SQLite + local attachments',
                ),
                enabled: !_busy,
                onTap: _busy
                    ? null
                    : _createBackup,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.restore_rounded,
                ),
                title: const Text(
                  'Restore backup',
                ),
                subtitle: const Text(
                  'Replace current local data',
                ),
                enabled: !_busy,
                onTap: _busy
                    ? null
                    : _restoreBackup,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.cleaning_services_outlined,
                ),
                title: const Text(
                  'Clean orphan files',
                ),
                subtitle: const Text(
                  'Remove attachment folders that no longer belong to a task',
                ),
                enabled: !_busy,
                onTap: _busy
                    ? null
                    : _cleanupOrphans,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.storage_rounded,
                ),
                title: const Text(
                  'Local storage',
                ),
                subtitle: usage.when(
                  data: (bytes) => Text(
                    _formatBytes(bytes),
                  ),
                  loading: () =>
                      const Text(
                    'Calculating…',
                  ),
                  error: (_, _) =>
                      const Text(
                    'Could not calculate',
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Refresh',
                  onPressed: () {
                    ref.invalidate(
                      storageUsageProvider,
                    );
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _busy = true;
    });

    File? backup;

    try {
      final service = ref.read(
        backupRestoreServiceProvider,
      );

      backup =
          await service.createBackup();

      await service.shareBackup(
        backup,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Backup created.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        _showError(
          'Could not create backup',
          error,
        );
      }
    } finally {
      if (backup != null &&
          await backup.exists()) {
        try {
          await backup.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    final picked =
        await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const [
        'zip',
      ],
    );

    final path =
        picked?.files.single.path;

    if (path == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final service = ref.read(
        backupRestoreServiceProvider,
      );

      final file = File(path);

      final inspection =
          await service.inspectBackup(
        file,
      );

      if (!mounted) {
        return;
      }

      final manifest =
          inspection.manifest;

      final confirmed =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.restore_rounded,
            ),
            title: const Text(
              'Restore backup?',
            ),
            content: Text(
              '${DateFormat('d MMM yyyy · HH:mm').format(manifest.createdAtUtc.toLocal())}\n'
              '${manifest.taskCount} tasks · ${manifest.attachmentCount} attachments\n\n'
              'Current local FlowTask data will be replaced.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  false,
                ),
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  true,
                ),
                child: const Text(
                  'Restore',
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      await service.restoreBackup(
        file,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons
                  .check_circle_outline_rounded,
            ),
            title: const Text(
              'Restore complete',
            ),
            content: const Text(
              'FlowTask will close now. Open it again to load the restored data and rebuild reminders.',
            ),
            actions: [
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                child: const Text(
                  'Close',
                ),
              ),
            ],
          );
        },
      );

      await SystemNavigator.pop();
    } catch (error) {
      if (mounted) {
        _showError(
          'Could not restore backup',
          error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _cleanupOrphans() async {
    setState(() {
      _busy = true;
    });

    try {
      final removed = await ref
          .read(trashServiceProvider)
          .cleanupOrphanAttachments();

      if (!mounted) {
        return;
      }

      ref.invalidate(
        storageUsageProvider,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            removed == 0
                ? 'No orphan attachment folders found.'
                : 'Removed $removed orphan attachment folder${removed == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        _showError(
          'Could not clean orphan files',
          error,
        );
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
    String title,
    Object error,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$title: $error',
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;

    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb = kb / 1024;

    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    final gb = mb / 1024;

    return '${gb.toStringAsFixed(2)} GB';
  }
}
