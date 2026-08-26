import 'package:drift/drift.dart';

import 'tasks.dart';

class Subtasks extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get title => text().withLength(
        min: 1,
        max: 500,
      )();

  BoolColumn get isCompleted => boolean().withDefault(
        const Constant(false),
      )();

  RealColumn get sortOrder => real().withDefault(
        const Constant(0),
      )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}