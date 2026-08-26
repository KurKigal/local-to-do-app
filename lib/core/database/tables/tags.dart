import 'package:drift/drift.dart';

class Tags extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 50,
      )();

  IntColumn get color => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}