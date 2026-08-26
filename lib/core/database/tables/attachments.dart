import 'package:drift/drift.dart';

import 'tasks.dart';

enum AttachmentType {
  image,
  video,
  file,
}

class Attachments extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get type => textEnum<AttachmentType>()();

  TextColumn get relativePath => text()();

  TextColumn get originalName => text()();

  TextColumn get mimeType => text().nullable()();

  IntColumn get size => integer()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}