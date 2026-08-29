import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks.dart';
import '../models/task_filter.dart';

class TaskQueryRepository {
  TaskQueryRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchFiltered(
    TaskFilter filter,
  ) {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day + 1,
    );

    final query = _db.select(_db.tasks);

    query.where((task) {
      var predicate =
          task.deletedAt.isNull() &
          task.status
              .equalsValue(
                TaskStatus.cancelled,
              )
              .not();

      predicate &= switch (filter.scope) {
        TaskListScope.all =>
          const Constant(true),
        TaskListScope.today =>
          task.status
                  .equalsValue(
                    TaskStatus.completed,
                  )
                  .not() &
              task.dueAt.isNotNull() &
              task.dueAt
                  .isBiggerOrEqualValue(today) &
              task.dueAt
                  .isSmallerThanValue(tomorrow),
        TaskListScope.upcoming =>
          task.status
                  .equalsValue(
                    TaskStatus.completed,
                  )
                  .not() &
              task.dueAt.isNotNull() &
              task.dueAt
                  .isBiggerOrEqualValue(tomorrow),
        TaskListScope.overdue =>
          task.status
                  .equalsValue(
                    TaskStatus.completed,
                  )
                  .not() &
              task.dueAt.isNotNull() &
              task.dueAt.isSmallerThanValue(today),
        TaskListScope.completed =>
          task.status.equalsValue(
            TaskStatus.completed,
          ),
      };

      final search =
          filter.query.trim();

      if (search.isNotEmpty) {
        final pattern = '%${_escapeLike(search)}%';

        predicate &=
            task.title.like(
              pattern,
              escapeChar: '\\',
            ) |
            task.description.like(
              pattern,
              escapeChar: '\\',
            );
      }

      if (filter.priorities.isNotEmpty) {
        predicate &= Expression.or(
          [
            for (final priority
                in filter.priorities)
              task.priority.equalsValue(
                priority,
              ),
          ],
        );
      }

      if (filter.projectIds.isNotEmpty) {
        predicate &=
            task.projectId.isIn(
          filter.projectIds,
        );
      }

      if (filter.tagIds.isNotEmpty) {
        for (final tagId
            in filter.tagIds) {
          final tagged = existsQuery(
            _db.select(_db.taskTags)
              ..where(
                (taskTag) =>
                    taskTag.taskId
                        .equalsExp(task.id) &
                    taskTag.tagId
                        .equals(tagId),
              ),
          );

          predicate &= tagged;
        }
      }

      return predicate;
    });

    query.orderBy([
      (task) => OrderingTerm.asc(
            task.sortOrder,
          ),
    ]);

    return query.watch().map(
      (items) {
        final sorted = [...items];

        sorted.sort(
          (a, b) => _compareTasks(
            a,
            b,
            filter.sort,
          ),
        );

        return sorted;
      },
    );
  }

  int _compareTasks(
    Task a,
    Task b,
    TaskSort sort,
  ) {
    return switch (sort) {
      TaskSort.dueDate =>
        _compareDueDate(a, b),
      TaskSort.priority =>
        _comparePriority(a, b),
      TaskSort.newest =>
        b.createdAt.compareTo(
          a.createdAt,
        ),
      TaskSort.oldest =>
        a.createdAt.compareTo(
          b.createdAt,
        ),
    };
  }

  int _compareDueDate(
    Task a,
    Task b,
  ) {
    final aDue = a.dueAt;
    final bDue = b.dueAt;

    if (aDue == null && bDue == null) {
      return a.sortOrder.compareTo(
        b.sortOrder,
      );
    }

    if (aDue == null) {
      return 1;
    }

    if (bDue == null) {
      return -1;
    }

    final result = aDue.compareTo(bDue);

    if (result != 0) {
      return result;
    }

    return _comparePriority(a, b);
  }

  int _comparePriority(
    Task a,
    Task b,
  ) {
    final result =
        _priorityWeight(b.priority)
            .compareTo(
      _priorityWeight(a.priority),
    );

    if (result != 0) {
      return result;
    }

    return _compareNullableDate(
      a.dueAt,
      b.dueAt,
    );
  }

  int _priorityWeight(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.none => 0,
      TaskPriority.low => 1,
      TaskPriority.medium => 2,
      TaskPriority.high => 3,
      TaskPriority.critical => 4,
    };
  }

  int _compareNullableDate(
    DateTime? a,
    DateTime? b,
  ) {
    if (a == null && b == null) {
      return 0;
    }

    if (a == null) {
      return 1;
    }

    if (b == null) {
      return -1;
    }

    return a.compareTo(b);
  }

  String _escapeLike(String value) {
    return value
        .replaceAll('\\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
