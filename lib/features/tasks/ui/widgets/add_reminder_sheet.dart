import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../providers/task_providers.dart';

enum _ReminderChoice {
  atDueTime,
  tenMinutes,
  oneHour,
  oneDay,
  custom,
}

Future<void> showAddReminderSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Task task,
}) async {
  final choice =
      await showModalBottomSheet<_ReminderChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Add reminder',
                ),
                titleTextStyle:
                    Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w800,
                        ),
              ),

              if (task.dueAt != null &&
                  task.hasDueTime) ...[
                ListTile(
                  leading: const Icon(
                    Icons.alarm_rounded,
                  ),
                  title: const Text(
                    'At due time',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      _ReminderChoice.atDueTime,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.timer_outlined,
                  ),
                  title: const Text(
                    '10 minutes before',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      _ReminderChoice.tenMinutes,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.schedule_rounded,
                  ),
                  title: const Text(
                    '1 hour before',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      _ReminderChoice.oneHour,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.calendar_today_outlined,
                  ),
                  title: const Text(
                    '1 day before',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      _ReminderChoice.oneDay,
                    );
                  },
                ),
              ],

              ListTile(
                leading: const Icon(
                  Icons.tune_rounded,
                ),
                title: const Text(
                  'Custom date & time',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    _ReminderChoice.custom,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == null) {
    return;
  }

  final repository =
      ref.read(
    reminderRepositoryProvider,
  );

  try {
    switch (choice) {
      case _ReminderChoice.atDueTime:
        await repository.createRelative(
          taskId: task.id,
          minutesBeforeDue: 0,
        );

      case _ReminderChoice.tenMinutes:
        await repository.createRelative(
          taskId: task.id,
          minutesBeforeDue: 10,
        );

      case _ReminderChoice.oneHour:
        await repository.createRelative(
          taskId: task.id,
          minutesBeforeDue: 60,
        );

      case _ReminderChoice.oneDay:
        await repository.createRelative(
          taskId: task.id,
          minutesBeforeDue: 1440,
        );

      case _ReminderChoice.custom:
        if (!context.mounted) {
          return;
        }

        final custom =
            await _pickCustomReminder(
          context,
          task,
        );

        if (custom == null) {
          return;
        }

        await repository.createAbsolute(
          taskId: task.id,
          scheduledAt: custom,
        );
    }
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Could not add reminder: $error',
        ),
      ),
    );
  }
}

Future<DateTime?> _pickCustomReminder(
  BuildContext context,
  Task task,
) async {
  final now = DateTime.now();

  final initial =
      task.dueAt != null &&
              task.dueAt!.isAfter(now)
          ? task.dueAt!
          : now.add(
              const Duration(hours: 1),
            );

  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(
      now.year,
      now.month,
      now.day,
    ),
    lastDate: DateTime(
      now.year + 20,
    ),
  );

  if (date == null ||
      !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime:
        TimeOfDay.fromDateTime(initial),
  );

  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}