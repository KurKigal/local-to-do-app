import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../projects/data/project_repository.dart';
import '../../tags/data/tag_repository.dart';

final projectRepositoryProvider =
    Provider<ProjectRepository>((ref) {
  return ProjectRepository(
    ref.watch(databaseProvider),
  );
});

final tagRepositoryProvider =
    Provider<TagRepository>((ref) {
  return TagRepository(
    ref.watch(databaseProvider),
  );
});

final projectsProvider =
    StreamProvider.autoDispose<List<Project>>((ref) {
  return ref
      .watch(projectRepositoryProvider)
      .watchAll();
});

final projectProvider = StreamProvider.autoDispose
    .family<Project?, String>((ref, projectId) {
  return ref
      .watch(projectRepositoryProvider)
      .watchById(projectId);
});

final projectTasksProvider = StreamProvider.autoDispose
    .family<List<Task>, String>((ref, projectId) {
  return ref
      .watch(projectRepositoryProvider)
      .watchTasks(projectId);
});

final allTagsProvider =
    StreamProvider.autoDispose<List<Tag>>((ref) {
  return ref
      .watch(tagRepositoryProvider)
      .watchAll();
});

final taskTagsProvider = StreamProvider.autoDispose
    .family<List<Tag>, String>((ref, taskId) {
  return ref
      .watch(tagRepositoryProvider)
      .watchForTask(taskId);
});
