import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../tasks/providers/task_providers.dart';
import '../data/trash_repository.dart';
import '../data/trash_service.dart';

final trashRepositoryProvider =
    Provider<TrashRepository>((ref) {
  return TrashRepository(
    ref.watch(databaseProvider),
  );
});

final trashServiceProvider =
    Provider<TrashService>((ref) {
  return TrashService(
    trash: ref.watch(
      trashRepositoryProvider,
    ),
    reminders: ref.watch(
      reminderRepositoryProvider,
    ),
    storage: ref.watch(
      attachmentStorageProvider,
    ),
    widgets: ref.watch(
      flowTaskWidgetServiceProvider,
    ),
  );
});

final trashTasksProvider =
    StreamProvider.autoDispose<List<Task>>(
  (ref) {
    return ref
        .watch(trashRepositoryProvider)
        .watchTrash();
  },
);
