import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/recurrences.dart';
import '../models/recurrence_rule.dart';

class RecurrenceRepository {
  RecurrenceRepository(this._db);

  final AppDatabase _db;

  static const _uuid = Uuid();

  Stream<Recurrence?> watchForTask(
    String taskId,
  ) {
    final query = _db.select(_db.recurrences)
      ..where(
        (recurrence) =>
            recurrence.taskId.equals(taskId),
      );

    return query.watchSingleOrNull();
  }

  Future<Recurrence?> getForTask(
    String taskId,
  ) {
    final query = _db.select(_db.recurrences)
      ..where(
        (recurrence) =>
            recurrence.taskId.equals(taskId),
      );

    return query.getSingleOrNull();
  }

  Future<RecurrenceRuleDraft?>
      getDraftForTask(
    String taskId,
  ) async {
    final recurrence =
        await getForTask(taskId);

    if (recurrence == null) {
      return null;
    }

    return toDraft(recurrence);
  }

  RecurrenceRuleDraft toDraft(
    Recurrence recurrence,
  ) {
    return RecurrenceRuleDraft(
      frequency: recurrence.frequency,
      interval: recurrence.interval,
      weekdays: _decodeWeekdays(
        recurrence.weekdays,
      ),
      endAt: recurrence.endAt,
      maxOccurrences:
          recurrence.maxOccurrences,
    );
  }

  Future<void> saveForTask({
    required String taskId,
    required RecurrenceRuleDraft? rule,
  }) async {
    final existing =
        await getForTask(taskId);

    if (rule == null) {
      if (existing != null) {
        await (_db.delete(_db.recurrences)
              ..where(
                (row) =>
                    row.id.equals(
                  existing.id,
                ),
              ))
            .go();
      }

      return;
    }

    final interval =
        rule.interval < 1 ? 1 : rule.interval;

    final weekdays =
        rule.frequency ==
                RecurrenceFrequency.weekly
            ? _encodeWeekdays(
                rule.weekdays,
              )
            : null;

    if (existing == null) {
      await _db.into(_db.recurrences).insert(
            RecurrencesCompanion.insert(
              id: _uuid.v4(),
              taskId: taskId,
              frequency: rule.frequency,
              interval: Value(interval),
              weekdays: Value(weekdays),
              endAt: Value(rule.endAt),
              maxOccurrences:
                  Value(rule.maxOccurrences),
            ),
          );

      return;
    }

    await (_db.update(_db.recurrences)
          ..where(
            (row) =>
                row.id.equals(existing.id),
          ))
        .write(
      RecurrencesCompanion(
        frequency: Value(rule.frequency),
        interval: Value(interval),
        weekdays: Value(weekdays),
        endAt: Value(rule.endAt),
        maxOccurrences:
            Value(rule.maxOccurrences),
      ),
    );
  }

  String? _encodeWeekdays(
    Set<int> weekdays,
  ) {
    if (weekdays.isEmpty) {
      return null;
    }

    final sorted = weekdays
        .where(
          (day) => day >= 1 && day <= 7,
        )
        .toList()
      ..sort();

    if (sorted.isEmpty) {
      return null;
    }

    return jsonEncode(sorted);
  }

  Set<int> _decodeWeekdays(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return {};
    }

    try {
      final decoded =
          jsonDecode(value);

      if (decoded is! List) {
        return {};
      }

      return decoded
          .whereType<num>()
          .map((value) => value.toInt())
          .where(
            (day) => day >= 1 && day <= 7,
          )
          .toSet();
    } catch (_) {
      return {};
    }
  }
}
