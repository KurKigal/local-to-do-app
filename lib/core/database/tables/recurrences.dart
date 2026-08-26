import 'package:drift/drift.dart';

import 'tasks.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class Recurrences extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get frequency =>
      textEnum<RecurrenceFrequency>()();

  IntColumn get interval => integer().withDefault(
        const Constant(1),
      )();

  /// ISO weekday values encoded as JSON.
  ///
  /// Monday = 1
  /// Sunday = 7
  ///
  /// Example: [1,3,5]
  TextColumn get weekdays => text().nullable()();

  /// Last allowed occurrence date/time.
  DateTimeColumn get endAt => dateTime().nullable()();

  /// Total number of occurrences in the series.
  /// The first task is occurrence 1.
  IntColumn get maxOccurrences => integer().nullable()();

  IntColumn get occurrenceNumber =>
      integer().withDefault(
        const Constant(1),
      )();

  /// Set after this occurrence creates its successor.
  /// This makes completion idempotent.
  TextColumn get nextOccurrenceTaskId =>
      text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
