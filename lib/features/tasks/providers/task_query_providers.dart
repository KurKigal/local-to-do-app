import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../data/task_query_repository.dart';
import '../models/task_filter.dart';

class TaskFilterNotifier
    extends Notifier<TaskFilter> {
  @override
  TaskFilter build() {
    return const TaskFilter();
  }

  void setQuery(String query) {
    state = state.copyWith(
      query: query,
    );
  }

  void setScope(
    TaskListScope scope,
  ) {
    state = state.copyWith(
      scope: scope,
    );
  }

  void replace(
    TaskFilter filter,
  ) {
    state = filter;
  }

  void clearAdvanced() {
    state = state.clearAdvanced();
  }

  void clearAll() {
    state = state.clearAll();
  }
}

final taskFilterProvider =
    NotifierProvider<
        TaskFilterNotifier,
        TaskFilter>(
  TaskFilterNotifier.new,
);

final taskQueryRepositoryProvider =
    Provider<TaskQueryRepository>((ref) {
  return TaskQueryRepository(
    ref.watch(databaseProvider),
  );
});

final filteredTasksProvider =
    StreamProvider.autoDispose<List<Task>>(
  (ref) {
    final filter =
        ref.watch(taskFilterProvider);

    return ref
        .watch(
          taskQueryRepositoryProvider,
        )
        .watchFiltered(filter);
  },
);
