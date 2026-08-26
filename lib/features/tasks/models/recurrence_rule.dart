import '../../../core/database/tables/recurrences.dart';

class RecurrenceRuleDraft {
  const RecurrenceRuleDraft({
    required this.frequency,
    this.interval = 1,
    this.weekdays = const {},
    this.endAt,
    this.maxOccurrences,
  });

  final RecurrenceFrequency frequency;
  final int interval;
  final Set<int> weekdays;
  final DateTime? endAt;
  final int? maxOccurrences;

  RecurrenceRuleDraft copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? weekdays,
    DateTime? endAt,
    bool clearEndAt = false,
    int? maxOccurrences,
    bool clearMaxOccurrences = false,
  }) {
    return RecurrenceRuleDraft(
      frequency:
          frequency ?? this.frequency,
      interval: interval ?? this.interval,
      weekdays:
          weekdays ?? this.weekdays,
      endAt:
          clearEndAt ? null : endAt ?? this.endAt,
      maxOccurrences: clearMaxOccurrences
          ? null
          : maxOccurrences ??
              this.maxOccurrences,
    );
  }
}

String recurrenceRuleLabel(
  RecurrenceRuleDraft? rule,
) {
  if (rule == null) {
    return 'Never';
  }

  final interval =
      rule.interval < 1 ? 1 : rule.interval;

  return switch (rule.frequency) {
    RecurrenceFrequency.daily =>
      interval == 1
          ? 'Every day'
          : 'Every $interval days',
    RecurrenceFrequency.weekly =>
      _weeklyLabel(rule, interval),
    RecurrenceFrequency.monthly =>
      interval == 1
          ? 'Every month'
          : 'Every $interval months',
    RecurrenceFrequency.yearly =>
      interval == 1
          ? 'Every year'
          : 'Every $interval years',
  };
}

String _weeklyLabel(
  RecurrenceRuleDraft rule,
  int interval,
) {
  if (rule.weekdays.isEmpty) {
    return interval == 1
        ? 'Every week'
        : 'Every $interval weeks';
  }

  final days = rule.weekdays.toList()..sort();

  final dayText = days
      .map(
        (day) => switch (day) {
          DateTime.monday => 'Mon',
          DateTime.tuesday => 'Tue',
          DateTime.wednesday => 'Wed',
          DateTime.thursday => 'Thu',
          DateTime.friday => 'Fri',
          DateTime.saturday => 'Sat',
          DateTime.sunday => 'Sun',
          _ => '?',
        },
      )
      .join(', ');

  if (interval == 1) {
    return dayText;
  }

  return '$dayText · every $interval weeks';
}
