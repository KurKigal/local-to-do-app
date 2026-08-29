import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../tasks/providers/task_providers.dart';
import '../data/backup_restore_service.dart';

final backupRestoreServiceProvider =
    Provider<BackupRestoreService>((ref) {
  return BackupRestoreService(
    database: ref.watch(
      databaseProvider,
    ),
    storage: ref.watch(
      attachmentStorageProvider,
    ),
    notifications: ref.watch(
      notificationServiceProvider,
    ),
  );
});

final storageUsageProvider =
    FutureProvider.autoDispose<int>(
  (ref) {
    return ref
        .watch(
          backupRestoreServiceProvider,
        )
        .storageUsageBytes();
  },
);
