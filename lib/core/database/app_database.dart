import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/attachments.dart';
import 'tables/projects.dart';
import 'tables/recurrences.dart';
import 'tables/reminders.dart';
import 'tables/subtasks.dart';
import 'tables/tags.dart';
import 'tables/task_tags.dart';
import 'tables/tasks.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    Projects,
    Subtasks,
    Tags,
    TaskTags,
    Reminders,
    Recurrences,
    Attachments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  static Future<File> databaseFile() async {
    final directory =
        await getApplicationDocumentsDirectory();

    return File(
      p.join(
        directory.path,
        'flowtask.sqlite',
      ),
    );
  }

  Future<void> exportInto(
    File target,
  ) async {
    await target.parent.create(
      recursive: true,
    );

    if (await target.exists()) {
      await target.delete();
    }

    await customStatement(
      'VACUUM INTO ?',
      [target.absolute.path],
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade:
          (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(
            tasks,
            tasks.hasDueTime,
          );
        }

        if (from < 3) {
          await migrator.addColumn(
            reminders,
            reminders.kind,
          );

          await migrator.addColumn(
            reminders,
            reminders.offsetMinutes,
          );

          await migrator.addColumn(
            reminders,
            reminders.snoozedUntil,
          );
        }

        if (from < 4) {
          await migrator.addColumn(
            recurrences,
            recurrences
                .occurrenceNumber,
          );

          await migrator.addColumn(
            recurrences,
            recurrences
                .nextOccurrenceTaskId,
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement(
          'PRAGMA foreign_keys = ON',
        );
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final file =
        await AppDatabase.databaseFile();

    final tempDirectory =
        await getTemporaryDirectory();

    sqlite3.tempDirectory =
        tempDirectory.path;

    return NativeDatabase
        .createInBackground(
      file,
    );
  });
}
