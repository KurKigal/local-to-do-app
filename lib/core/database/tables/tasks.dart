import 'package:drift/drift.dart';

enum TaskStatus {
  todo,
  inProgress,
  waiting,
  completed,
  cancelled,
}

enum TaskPriority {
  none,
  low,
  medium,
  high,
  critical,
}

class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get projectId => text().nullable()();

  TextColumn get title => text().withLength(
        min: 1,
        max: 500,
      )();

  TextColumn get description => text().nullable()();

  TextColumn get status => textEnum<TaskStatus>()();

  TextColumn get priority => textEnum<TaskPriority>()();

  DateTimeColumn get startAt => dateTime().nullable()();

  DateTimeColumn get dueAt => dateTime().nullable()();

  BoolColumn get hasDueTime => boolean().withDefault(
        const Constant(false),
      )();

  RealColumn get sortOrder => real().withDefault(
        const Constant(0),
      )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}