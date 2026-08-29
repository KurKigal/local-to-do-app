import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/attachment_storage.dart';
import '../models/backup_manifest.dart';

class BackupInspection {
  const BackupInspection({
    required this.manifest,
    required this.file,
  });

  final BackupManifest manifest;
  final File file;
}

class BackupRestoreService {
  BackupRestoreService({
    required AppDatabase database,
    required AttachmentStorage storage,
    required NotificationService notifications,
  })  : _database = database,
        _storage = storage,
        _notifications = notifications;

  final AppDatabase _database;
  final AttachmentStorage _storage;
  final NotificationService _notifications;

  Future<File> createBackup() async {
    final temp =
        await getTemporaryDirectory();

    final work = Directory(
      p.join(
        temp.path,
        'flowtask_backup_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    await work.create(recursive: true);

    try {
      final snapshot = File(
        p.join(work.path, 'flowtask.sqlite'),
      );

      await _database.exportInto(snapshot);

      final tasks =
          await _database.select(_database.tasks).get();

      final attachments =
          await _database
              .select(_database.attachments)
              .get();

      final manifest = BackupManifest(
        formatVersion:
            BackupManifest.currentFormatVersion,
        createdAtUtc: DateTime.now().toUtc(),
        databaseSchemaVersion:
            _database.schemaVersion,
        taskCount: tasks.length,
        attachmentCount:
            attachments.length,
      );

      final manifestFile = File(
        p.join(work.path, 'manifest.json'),
      );

      await manifestFile.writeAsString(
        manifest.encode(),
        flush: true,
      );

      final output = File(
        p.join(
          temp.path,
          _backupFileName(),
        ),
      );

      if (await output.exists()) {
        await output.delete();
      }

      final encoder = ZipFileEncoder()
        ..create(output.path);

      try {
        await encoder.addFile(
          manifestFile,
          'manifest.json',
        );

        await encoder.addFile(
          snapshot,
          'flowtask.sqlite',
        );

        final attachmentRoot =
            await _storage.rootDirectory();

        if (await attachmentRoot.exists()) {
          await encoder.addDirectory(
            attachmentRoot,
            includeDirName: true,
          );
        }
      } finally {
        await encoder.close();
      }

      return output;
    } finally {
      if (await work.exists()) {
        await work.delete(recursive: true);
      }
    }
  }

  Future<void> shareBackup(
    File backup,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'FlowTask backup',
        files: [
          XFile(
            backup.path,
            name: p.basename(backup.path),
            mimeType: 'application/zip',
          ),
        ],
        fileNameOverrides: [
          p.basename(backup.path),
        ],
      ),
    );
  }

  Future<BackupInspection> inspectBackup(
    File backup,
  ) async {
    final extracted =
        await _extractAndValidate(backup);

    try {
      return BackupInspection(
        manifest: extracted.manifest,
        file: backup,
      );
    } finally {
      await extracted.directory.delete(
        recursive: true,
      );
    }
  }

  Future<void> restoreBackup(
    File backup,
  ) async {
    final extracted =
        await _extractAndValidate(backup);

    final documents =
        await getApplicationDocumentsDirectory();

    sqlite3.tempDirectory =
        (await getTemporaryDirectory()).path;

    final newDatabase = File(
      p.join(
        documents.path,
        '.flowtask_restore_new.sqlite',
      ),
    );

    final stagedAttachments = Directory(
      p.join(
        documents.path,
        '.flowtask_restore_attachments',
      ),
    );

    try {
      if (await newDatabase.exists()) {
        await newDatabase.delete();
      }

      final source = sqlite3.open(
        extracted.database.path,
      );

      try {
        source.execute(
          'VACUUM INTO ?',
          [newDatabase.path],
        );
      } finally {
        source.close();
      }

      if (await stagedAttachments.exists()) {
        await stagedAttachments.delete(
          recursive: true,
        );
      }

      await stagedAttachments.create(
        recursive: true,
      );

      if (await extracted.attachments.exists()) {
        await _copyDirectoryContents(
          extracted.attachments,
          stagedAttachments,
        );
      }

      // AlarmManager state is not part of the backup.
      // Remove schedules belonging to the current dataset.
      final pending =
          await _notifications
              .getPendingNotifications();

      for (final request in pending) {
        await _notifications.cancel(
          request.id,
        );
      }

      // Write recovery intent before replacing the database.
      // If anything after this point fails, the next app start can
      // still rebuild reminder schedules from whichever DB survived.
      final marker = File(
        p.join(
          documents.path,
          '.flowtask_restore_pending',
        ),
      );

      await marker.writeAsString(
        DateTime.now()
            .toUtc()
            .toIso8601String(),
        flush: true,
      );

      await _replaceLiveData(
        newDatabase: newDatabase,
        newAttachments:
            stagedAttachments,
      );
    } finally {
      if (await extracted.directory.exists()) {
        await extracted.directory.delete(
          recursive: true,
        );
      }

      if (await newDatabase.exists()) {
        await newDatabase.delete();
      }

      if (await stagedAttachments.exists()) {
        await stagedAttachments.delete(
          recursive: true,
        );
      }
    }
  }

  Future<int> storageUsageBytes() async {
    var total = 0;

    final database =
        await AppDatabase.databaseFile();

    for (final path in [
      database.path,
      '${database.path}-wal',
      '${database.path}-shm',
    ]) {
      final file = File(path);

      if (await file.exists()) {
        total += await file.length();
      }
    }

    total += await _directorySize(
      await _storage.rootDirectory(),
    );

    return total;
  }

  Future<_ExtractedBackup>
      _extractAndValidate(
    File backup,
  ) async {
    if (!await backup.exists() ||
        p.extension(backup.path).toLowerCase() !=
            '.zip') {
      throw const FormatException(
        'Select a FlowTask ZIP backup.',
      );
    }

    final temp =
        await getTemporaryDirectory();

    final directory = Directory(
      p.join(
        temp.path,
        'flowtask_restore_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    await directory.create(
      recursive: true,
    );

    try {
      await extractFileToDisk(
        backup.path,
        directory.path,
      );

      final manifestFile = File(
        p.join(
          directory.path,
          'manifest.json',
        ),
      );

      final database = File(
        p.join(
          directory.path,
          'flowtask.sqlite',
        ),
      );

      if (!await manifestFile.exists() ||
          !await database.exists()) {
        throw const FormatException(
          'Backup is missing required files.',
        );
      }

      final manifest =
          BackupManifest.decode(
        await manifestFile.readAsString(),
      );

      if (manifest.formatVersion >
          BackupManifest
              .currentFormatVersion) {
        throw const FormatException(
          'This backup uses a newer FlowTask backup format.',
        );
      }

      if (manifest.databaseSchemaVersion >
          _database.schemaVersion) {
        throw const FormatException(
          'Update FlowTask before restoring this newer database.',
        );
      }

      _validateDatabase(database);

      return _ExtractedBackup(
        directory: directory,
        manifest: manifest,
        database: database,
        attachments: Directory(
          p.join(
            directory.path,
            'attachments',
          ),
        ),
      );
    } catch (_) {
      if (await directory.exists()) {
        await directory.delete(
          recursive: true,
        );
      }

      rethrow;
    }
  }

  void _validateDatabase(
    File file,
  ) {
    final database =
        sqlite3.open(file.path);

    try {
      final integrity =
          database.select(
        'PRAGMA integrity_check',
      );

      if (integrity.isEmpty ||
          integrity.first.values.first !=
              'ok') {
        throw const FormatException(
          'SQLite integrity check failed.',
        );
      }

      final tables = database
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          )
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();

      const requiredTables = {
        'tasks',
        'projects',
        'subtasks',
        'tags',
        'task_tags',
        'reminders',
        'recurrences',
        'attachments',
      };

      if (!tables.containsAll(
        requiredTables,
      )) {
        throw const FormatException(
          'Backup database is missing FlowTask tables.',
        );
      }

      final versions =
          database.select(
        'PRAGMA user_version',
      );

      final userVersion =
          versions.isEmpty
              ? 0
              : versions.first
                  .values.first as int;

      if (userVersion >
          _database.schemaVersion) {
        throw const FormatException(
          'Backup database is newer than this FlowTask version.',
        );
      }
    } finally {
      database.close();
    }
  }

  Future<void> _replaceLiveData({
    required File newDatabase,
    required Directory newAttachments,
  }) async {
    final liveDatabase =
        await AppDatabase.databaseFile();

    final liveAttachments =
        await _storage.rootDirectory();

    final oldDatabase = File(
      '${liveDatabase.path}.restore_old',
    );

    final oldAttachments = Directory(
      '${liveAttachments.path}.restore_old',
    );

    if (await oldDatabase.exists()) {
      await oldDatabase.delete();
    }

    if (await oldAttachments.exists()) {
      await oldAttachments.delete(
        recursive: true,
      );
    }

    await _database.close();

    for (final suffix in [
      '-wal',
      '-shm',
    ]) {
      final sidecar = File(
        '${liveDatabase.path}$suffix',
      );

      if (await sidecar.exists()) {
        await sidecar.delete();
      }
    }

    var oldDbMoved = false;
    var oldAttachmentsMoved = false;
    var newDbInstalled = false;
    var newAttachmentsInstalled = false;

    try {
      if (await liveDatabase.exists()) {
        await liveDatabase.rename(
          oldDatabase.path,
        );
        oldDbMoved = true;
      }

      if (await liveAttachments.exists()) {
        await liveAttachments.rename(
          oldAttachments.path,
        );
        oldAttachmentsMoved = true;
      }

      await newDatabase.rename(
        liveDatabase.path,
      );
      newDbInstalled = true;

      await newAttachments.rename(
        liveAttachments.path,
      );
      newAttachmentsInstalled = true;
    } catch (_) {
      if (newAttachmentsInstalled &&
          await liveAttachments.exists()) {
        await liveAttachments.delete(
          recursive: true,
        );
      }

      if (newDbInstalled &&
          await liveDatabase.exists()) {
        await liveDatabase.delete();
      }

      if (oldDbMoved &&
          await oldDatabase.exists()) {
        await oldDatabase.rename(
          liveDatabase.path,
        );
      }

      if (oldAttachmentsMoved &&
          await oldAttachments.exists()) {
        await oldAttachments.rename(
          liveAttachments.path,
        );
      }

      rethrow;
    }

    // Successful commit: rollback copies are no longer needed.
    // Cleanup must never invalidate an otherwise successful restore.
    if (oldDbMoved &&
        await oldDatabase.exists()) {
      try {
        await oldDatabase.delete();
      } catch (_) {}
    }

    if (oldAttachmentsMoved &&
        await oldAttachments.exists()) {
      try {
        await oldAttachments.delete(
          recursive: true,
        );
      } catch (_) {}
    }
  }

  Future<void> _copyDirectoryContents(
    Directory source,
    Directory destination,
  ) async {
    await for (final entity
        in source.list()) {
      final target = p.join(
        destination.path,
        p.basename(entity.path),
      );

      if (entity is Directory) {
        final child =
            Directory(target);

        await child.create(
          recursive: true,
        );

        await _copyDirectoryContents(
          entity,
          child,
        );
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }

  Future<int> _directorySize(
    Directory directory,
  ) async {
    if (!await directory.exists()) {
      return 0;
    }

    var total = 0;

    await for (final entity
        in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        total += await entity.length();
      }
    }

    return total;
  }

  String _backupFileName() {
    final now = DateTime.now();

    String two(int value) =>
        value.toString().padLeft(
          2,
          '0',
        );

    return 'flowtask-backup-${now.year}-${two(now.month)}-${two(now.day)}-${two(now.hour)}${two(now.minute)}.zip';
  }
}

class _ExtractedBackup {
  const _ExtractedBackup({
    required this.directory,
    required this.manifest,
    required this.database,
    required this.attachments,
  });

  final Directory directory;
  final BackupManifest manifest;
  final File database;
  final Directory attachments;
}
