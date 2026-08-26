import 'package:drift/drift.dart';

import 'tasks.dart';

enum ReminderKind {
  absolute,
  relativeToDue,
}

class Reminders extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get kind =>
      textEnum<ReminderKind>().withDefault(
        const Constant('absolute'),
      )();

  /// Canonical reminder time.
  DateTimeColumn get scheduledAt => dateTime()();

  /// relativeToDue için:
  ///
  /// 0  -> due time
  /// 10 -> 10 dakika önce
  /// 60 -> 1 saat önce
  IntColumn get offsetMinutes =>
      integer().nullable()();

  /// Snooze canonical scheduledAt'i bozmaz.
  DateTimeColumn get snoozedUntil =>
      dateTime().nullable()();

  IntColumn get notificationId => integer()();

  BoolColumn get isEnabled =>
      boolean().withDefault(
        const Constant(true),
      )();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}