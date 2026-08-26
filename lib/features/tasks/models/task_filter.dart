import '../../../core/database/tables/tasks.dart';

enum TaskListScope {
  all,
  today,
  upcoming,
  overdue,
  completed,
}

enum TaskSort {
  dueDate,
  priority,
  newest,
  oldest,
}

class TaskFilter {
  const TaskFilter({
    this.query = '',
    this.scope = TaskListScope.all,
    this.priorities = const {},
    this.projectIds = const {},
    this.tagIds = const {},
    this.sort = TaskSort.dueDate,
  });

  final String query;
  final TaskListScope scope;
  final Set<TaskPriority> priorities;
  final Set<String> projectIds;
  final Set<String> tagIds;
  final TaskSort sort;

  bool get hasAdvancedFilters =>
      priorities.isNotEmpty ||
      projectIds.isNotEmpty ||
      tagIds.isNotEmpty ||
      sort != TaskSort.dueDate;

  int get advancedFilterCount {
    var count = 0;

    if (priorities.isNotEmpty) {
      count++;
    }

    if (projectIds.isNotEmpty) {
      count++;
    }

    if (tagIds.isNotEmpty) {
      count++;
    }

    if (sort != TaskSort.dueDate) {
      count++;
    }

    return count;
  }

  TaskFilter copyWith({
    String? query,
    TaskListScope? scope,
    Set<TaskPriority>? priorities,
    Set<String>? projectIds,
    Set<String>? tagIds,
    TaskSort? sort,
  }) {
    return TaskFilter(
      query: query ?? this.query,
      scope: scope ?? this.scope,
      priorities:
          priorities ?? this.priorities,
      projectIds:
          projectIds ?? this.projectIds,
      tagIds: tagIds ?? this.tagIds,
      sort: sort ?? this.sort,
    );
  }

  TaskFilter clearAdvanced() {
    return copyWith(
      priorities: const {},
      projectIds: const {},
      tagIds: const {},
      sort: TaskSort.dueDate,
    );
  }

  TaskFilter clearAll() {
    return const TaskFilter();
  }
}
