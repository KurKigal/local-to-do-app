import 'package:flutter/material.dart';

import '../../../../core/database/tables/recurrences.dart';
import '../../models/recurrence_rule.dart';

class RecurrenceEditorResult {
  const RecurrenceEditorResult(
    this.rule,
  );

  final RecurrenceRuleDraft? rule;
}

enum _EndMode {
  never,
  onDate,
  afterCount,
}

Future<RecurrenceEditorResult?>
    showRecurrenceEditorSheet({
  required BuildContext context,
  required RecurrenceRuleDraft?
      initialRule,
  required DateTime dueAt,
}) {
  return showModalBottomSheet<
      RecurrenceEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _RecurrenceEditorSheet(
      initialRule: initialRule,
      dueAt: dueAt,
    ),
  );
}

class _RecurrenceEditorSheet
    extends StatefulWidget {
  const _RecurrenceEditorSheet({
    required this.initialRule,
    required this.dueAt,
  });

  final RecurrenceRuleDraft? initialRule;
  final DateTime dueAt;

  @override
  State<_RecurrenceEditorSheet>
      createState() =>
          _RecurrenceEditorSheetState();
}

class _RecurrenceEditorSheetState
    extends State<_RecurrenceEditorSheet> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late Set<int> _weekdays;
  late _EndMode _endMode;
  DateTime? _endAt;
  int _maxOccurrences = 10;

  @override
  void initState() {
    super.initState();

    final rule = widget.initialRule;

    _frequency =
        rule?.frequency ??
            RecurrenceFrequency.daily;

    _interval =
        rule?.interval ?? 1;

    _weekdays = {
      ...?rule?.weekdays,
    };

    if (rule == null &&
        _frequency ==
            RecurrenceFrequency.weekly) {
      _weekdays.add(
        widget.dueAt.weekday,
      );
    }

    if (rule?.endAt != null) {
      _endMode = _EndMode.onDate;
      _endAt = rule!.endAt;
    } else if (rule?.maxOccurrences !=
        null) {
      _endMode = _EndMode.afterCount;
      _maxOccurrences =
          rule!.maxOccurrences!;
    } else {
      _endMode = _EndMode.never;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.90,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              12,
              10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Repeat',
                    style: theme
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.initialRule !=
                    null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const RecurrenceEditorResult(
                          null,
                        ),
                      );
                    },
                    child: const Text(
                      'Never',
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                30,
              ),
              children: [
                const _SectionLabel(
                  'Frequency',
                ),
                const SizedBox(height: 12),
                SegmentedButton<
                    RecurrenceFrequency>(
                  segments: const [
                    ButtonSegment(
                      value:
                          RecurrenceFrequency
                              .daily,
                      label: Text('Day'),
                    ),
                    ButtonSegment(
                      value:
                          RecurrenceFrequency
                              .weekly,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value:
                          RecurrenceFrequency
                              .monthly,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value:
                          RecurrenceFrequency
                              .yearly,
                      label: Text('Year'),
                    ),
                  ],
                  selected: {
                    _frequency,
                  },
                  onSelectionChanged:
                      (values) {
                    setState(() {
                      _frequency =
                          values.first;

                      if (_frequency ==
                              RecurrenceFrequency
                                  .weekly &&
                          _weekdays
                              .isEmpty) {
                        _weekdays.add(
                          widget
                              .dueAt
                              .weekday,
                        );
                      }
                    });
                  },
                ),
                const SizedBox(height: 28),
                const _SectionLabel(
                  'Interval',
                ),
                const SizedBox(height: 10),
                _CounterTile(
                  value: _interval,
                  label:
                      _intervalLabel(),
                  minimum: 1,
                  maximum: 365,
                  onChanged: (value) {
                    setState(() {
                      _interval = value;
                    });
                  },
                ),
                if (_frequency ==
                    RecurrenceFrequency
                        .weekly) ...[
                  const SizedBox(height: 28),
                  const _SectionLabel(
                    'Days',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var day = 1;
                          day <= 7;
                          day++)
                        FilterChip(
                          label: Text(
                            _dayLabel(day),
                          ),
                          selected:
                              _weekdays
                                  .contains(day),
                          onSelected:
                              (selected) {
                            setState(() {
                              if (selected) {
                                _weekdays
                                    .add(day);
                              } else if (_weekdays
                                      .length >
                                  1) {
                                _weekdays
                                    .remove(day);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                const _SectionLabel(
                  'Ends',
                ),
                const SizedBox(height: 10),
                RadioGroup<_EndMode>(
                  groupValue: _endMode,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _endMode = value;
                    });
                  },
                  child: Column(
                    children: [
                      const RadioListTile(
                        value: _EndMode.never,
                        title:
                            Text('Never'),
                      ),
                      RadioListTile(
                        value:
                            _EndMode.onDate,
                        title: const Text(
                          'On date',
                        ),
                        subtitle: _endAt ==
                                null
                            ? null
                            : Text(
                                _formatDate(
                                  _endAt!,
                                ),
                              ),
                        secondary: IconButton(
                          onPressed:
                              _pickEndDate,
                          icon: const Icon(
                            Icons
                                .calendar_today_outlined,
                          ),
                        ),
                      ),
                      RadioListTile(
                        value: _EndMode
                            .afterCount,
                        title: const Text(
                          'After total occurrences',
                        ),
                        subtitle: Text(
                          '$_maxOccurrences tasks in the series',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_endMode ==
                    _EndMode.afterCount) ...[
                  const SizedBox(height: 10),
                  _CounterTile(
                    value:
                        _maxOccurrences,
                    label:
                        'Total occurrences',
                    minimum: 1,
                    maximum: 9999,
                    onChanged: (value) {
                      setState(() {
                        _maxOccurrences =
                            value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 30),
                Container(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: theme
                        .colorScheme
                        .primaryContainer
                        .withValues(
                          alpha: 0.45,
                        ),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .repeat_rounded,
                        color: theme
                            .colorScheme
                            .primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recurrenceRuleLabel(
                            _buildRule(),
                          ),
                          style: theme
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme
                      .colorScheme
                      .outlineVariant,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(
                  Icons.check_rounded,
                ),
                label: const Text(
                  'Save repeat',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RecurrenceRuleDraft _buildRule() {
    return RecurrenceRuleDraft(
      frequency: _frequency,
      interval: _interval,
      weekdays: _frequency ==
              RecurrenceFrequency.weekly
          ? {..._weekdays}
          : const {},
      endAt:
          _endMode == _EndMode.onDate
              ? _endAt
              : null,
      maxOccurrences:
          _endMode ==
                  _EndMode.afterCount
              ? _maxOccurrences
              : null,
    );
  }

  void _save() {
    if (_frequency ==
            RecurrenceFrequency.weekly &&
        _weekdays.isEmpty) {
      return;
    }

    if (_endMode ==
            _EndMode.onDate &&
        _endAt == null) {
      return;
    }

    Navigator.pop(
      context,
      RecurrenceEditorResult(
        _buildRule(),
      ),
    );
  }

  Future<void> _pickEndDate() async {
    final initial =
        _endAt ??
            widget.dueAt.add(
              const Duration(days: 30),
            );

    final selected =
        await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(
        widget.dueAt.year,
        widget.dueAt.month,
        widget.dueAt.day,
      ),
      lastDate: DateTime(
        widget.dueAt.year + 30,
      ),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _endMode = _EndMode.onDate;
      _endAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
        999,
      );
    });
  }

  String _intervalLabel() {
    final unit =
        switch (_frequency) {
      RecurrenceFrequency.daily =>
        _interval == 1
            ? 'day'
            : 'days',
      RecurrenceFrequency.weekly =>
        _interval == 1
            ? 'week'
            : 'weeks',
      RecurrenceFrequency.monthly =>
        _interval == 1
            ? 'month'
            : 'months',
      RecurrenceFrequency.yearly =>
        _interval == 1
            ? 'year'
            : 'years',
    };

    return 'Every $_interval $unit';
  }

  String _dayLabel(int day) {
    return switch (day) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '?',
    };
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(
      2,
      '0',
    );
    final month =
        date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day.$month.${date.year}';
  }
}

class _CounterTile
    extends StatelessWidget {
  const _CounterTile({
    required this.value,
    required this.label,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
  });

  final int value;
  final String label;
  final int minimum;
  final int maximum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLow,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > minimum
                ? () => onChanged(
                      value - 1,
                    )
                : null,
            icon: const Icon(
              Icons.remove_rounded,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value < maximum
                ? () => onChanged(
                      value + 1,
                    )
                : null,
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel
    extends StatelessWidget {
  const _SectionLabel(
    this.label,
  );

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
