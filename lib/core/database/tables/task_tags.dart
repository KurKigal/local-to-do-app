import 'package:drift/drift.dart';

import 'tags.dart';
import 'tasks.dart';

class TaskTags extends Table {
  TextColumn get taskId => text().references(
        Tasks,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get tagId => text().references(
        Tags,
        #id,
        onDelete: KeyAction.cascade,
      )();

  @override
  Set<Column<Object>> get primaryKey => {
        taskId,
        tagId,
      };
}