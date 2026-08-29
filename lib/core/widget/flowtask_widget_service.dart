import 'package:drift/drift.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../database/tables/tasks.dart';

class FlowTaskWidgetService {
  FlowTaskWidgetService(
    this._database,
  );

  final AppDatabase _database;

  static const qualifiedAndroidName =
      'com.emirhankeser.flowtask.FlowTaskWidgetProvider';

  Future<void> refresh() async {
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

    final query =
        _database.select(_database.tasks)
          ..where(
            (task) =>
                task.deletedAt.isNull() &
                task.status
                    .equalsValue(
                      TaskStatus.completed,
                    )
                    .not() &
                task.status
                    .equalsValue(
                      TaskStatus.cancelled,
                    )
                    .not() &
                task.dueAt.isNotNull() &
                task.dueAt
                    .isBiggerOrEqualValue(
                      today,
                    ) &
                task.dueAt
                    .isSmallerThanValue(
                      tomorrow,
                    ),
          )
          ..orderBy([
            (task) => OrderingTerm.asc(
                  task.dueAt,
                ),
            (task) => OrderingTerm.asc(
                  task.sortOrder,
                ),
          ]);

    final tasks = await query.get();

    await HomeWidget.saveWidgetData<String>(
      'widget_date',
      DateFormat('EEE, d MMM').format(now),
    );

    await HomeWidget.saveWidgetData<int>(
      'widget_count',
      tasks.length,
    );

    for (var index = 0;
        index < 3;
        index++) {
      final task =
          index < tasks.length
              ? tasks[index]
              : null;

      await HomeWidget.saveWidgetData<String>(
        'widget_task_${index}_id',
        task?.id ?? '',
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_task_${index}_title',
        task?.title ?? '',
      );

      await HomeWidget.saveWidgetData<String>(
        'widget_task_${index}_due',
        task == null
            ? ''
            : _dueLabel(task),
      );
    }

    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          qualifiedAndroidName,
    );
  }

  String _dueLabel(
    Task task,
  ) {
    final dueAt = task.dueAt;

    if (dueAt == null ||
        !task.hasDueTime) {
      return '';
    }

    return DateFormat('HH:mm').format(
      dueAt,
    );
  }

  static Future<void>
      refreshStandalone() async {
    final database =
        AppDatabase();

    try {
      await FlowTaskWidgetService(
        database,
      ).refresh();
    } finally {
      await database.close();
    }
  }
}
