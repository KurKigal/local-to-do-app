import 'package:drift/drift.dart';

class Projects extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 100,
      )();

  TextColumn get icon => text().nullable()();

  IntColumn get color => integer().nullable()();

  RealColumn get sortOrder => real().withDefault(
        const Constant(0),
      )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}