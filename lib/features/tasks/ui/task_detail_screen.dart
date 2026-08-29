import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/attachments.dart';
import '../../../core/database/tables/reminders.dart';
import '../../../core/database/tables/tasks.dart';
import '../../organization/providers/organization_providers.dart';
import '../models/recurrence_rule.dart';
import '../providers/task_providers.dart';
import 'attachment_viewer_screen.dart';
import 'widgets/add_attachment_sheet.dart';
import 'widgets/add_reminder_sheet.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({
    required this.taskId,
    super.key,
  });

  final String taskId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final taskAsync = ref.watch(
      taskProvider(taskId),
    );

    return taskAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('$error'),
        ),
      ),
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Task not found'),
            ),
          );
        }

        return _TaskDetailContent(
          task: task,
        );
      },
    );
  }
}

class _TaskDetailContent extends ConsumerWidget {
  const _TaskDetailContent({
    required this.task,
  });

  final Task task;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    final project = task.projectId == null
        ? null
        : ref.watch(
            projectProvider(task.projectId!),
          );

    final tags = ref.watch(
      taskTagsProvider(task.id),
    );

    final recurrence = ref.watch(
      recurrenceProvider(task.id),
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () {
              context.push(
                '/task/${task.id}/edit',
              );
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value != 'delete') {
                return;
              }

              await ref
                  .read(taskServiceProvider)
                  .moveToTrash(task.id);

              if (context.mounted) {
                context.pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Move to trash',
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          120,
        ),
        children: [
          Text(
            task.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (task.priority != TaskPriority.none)
                _PriorityChip(
                  priority: task.priority,
                ),
              if (task.status == TaskStatus.completed)
                const Chip(
                  avatar: Icon(
                    Icons.check_rounded,
                    size: 16,
                  ),
                  label: Text('Completed'),
                ),
            ],
          ),
          if (task.description != null) ...[
            const SizedBox(height: 24),
            Text(
              task.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.55,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
          if (task.dueAt != null) ...[
            const SizedBox(height: 28),
            _SurfaceCard(
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      task.hasDueTime
                          ? DateFormat(
                              'EEE, d MMM · HH:mm',
                            ).format(task.dueAt!)
                          : DateFormat(
                              'EEE, d MMM yyyy',
                            ).format(task.dueAt!),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (task.projectId != null ||
              (tags.valueOrNull?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (project?.valueOrNull != null)
                  ActionChip(
                    avatar: const Icon(
                      Icons.folder_outlined,
                      size: 18,
                    ),
                    label: Text(
                      project!.valueOrNull!.name,
                    ),
                    onPressed: () {
                      context.push(
                        '/project/${project.valueOrNull!.id}',
                      );
                    },
                  ),
                ...?tags.valueOrNull?.map(
                  (tag) => Chip(
                    avatar: Icon(
                      Icons.sell_outlined,
                      size: 16,
                      color: tag.color == null
                          ? null
                          : Color(tag.color!),
                    ),
                    label: Text(tag.name),
                  ),
                ),
              ],
            ),
          ],
          if (recurrence.valueOrNull != null) ...[
            const SizedBox(height: 16),
            _SurfaceCard(
              child: Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      recurrenceRuleLabel(
                        RecurrenceRuleDraft(
                          frequency: recurrence.valueOrNull!.frequency,
                          interval: recurrence.valueOrNull!.interval,
                          weekdays: _decodeRecurrenceWeekdays(
                            recurrence.valueOrNull!.weekdays,
                          ),
                          endAt: recurrence.valueOrNull!.endAt,
                          maxOccurrences:
                              recurrence.valueOrNull!.maxOccurrences,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          _ReminderSection(
            task: task,
          ),
          const SizedBox(height: 32),
          _SubtaskSection(
            taskId: task.id,
          ),
          const SizedBox(height: 32),
          _AttachmentSection(
            taskId: task.id,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(taskServiceProvider)
                  .setCompleted(
                    task.id,
                    completed:
                        task.status !=
                            TaskStatus.completed,
                  );
            },
            icon: Icon(
              task.status == TaskStatus.completed
                  ? Icons.undo_rounded
                  : Icons.check_rounded,
            ),
            label: Text(
              task.status == TaskStatus.completed
                  ? 'Mark as incomplete'
                  : 'Complete task',
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSection extends ConsumerWidget {
  const _ReminderSection({
    required this.task,
  });

  final Task task;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final reminders = ref.watch(
      remindersProvider(task.id),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reminders',
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add reminder',
              onPressed: () {
                showAddReminderSheet(
                  context: context,
                  ref: ref,
                  task: task,
                );
              },
              icon: const Icon(
                Icons.add_alarm_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        reminders.when(
          loading: () =>
              const LinearProgressIndicator(),
          error: (error, stack) =>
              Text('$error'),
          data: (items) {
            final active = items.where(
              (reminder) {
                final effective =
                    reminder.snoozedUntil ??
                        reminder.scheduledAt;

                return effective.isAfter(
                  DateTime.now(),
                );
              },
            ).toList();

            if (active.isEmpty) {
              return Text(
                'No active reminders',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              );
            }

            return Column(
              children: [
                for (final reminder in active) ...[
                  _ReminderTile(
                    reminder: reminder,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({
    required this.reminder,
  });

  final Reminder reminder;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final effective =
        reminder.snoozedUntil ??
            reminder.scheduledAt;

    return _SurfaceCard(
      child: Row(
        children: [
          Icon(
            reminder.snoozedUntil != null
                ? Icons.snooze_rounded
                : Icons
                    .notifications_active_outlined,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _title(reminder),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat(
                    'EEE, d MMM · HH:mm',
                  ).format(effective),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color:
                            Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete reminder',
            onPressed: () {
              ref
                  .read(
                    reminderRepositoryProvider,
                  )
                  .delete(reminder.id);
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _title(Reminder reminder) {
    if (reminder.snoozedUntil != null) {
      return 'Snoozed';
    }

    if (reminder.kind ==
        ReminderKind.absolute) {
      return 'Custom reminder';
    }

    return switch (
        reminder.offsetMinutes ?? 0) {
      0 => 'At due time',
      10 => '10 minutes before',
      60 => '1 hour before',
      1440 => '1 day before',
      final minutes =>
        '$minutes minutes before',
    };
  }
}

class _SubtaskSection extends ConsumerWidget {
  const _SubtaskSection({
    required this.taskId,
  });

  final String taskId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final subtasks = ref.watch(
      subtasksProvider(taskId),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Subtasks',
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add subtask',
              onPressed: () =>
                  _showAddSubtask(
                context,
                ref,
              ),
              icon: const Icon(
                Icons.add_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        subtasks.when(
          loading: () =>
              const LinearProgressIndicator(),
          error: (error, stack) =>
              Text('$error'),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'No subtasks',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              );
            }

            return _SurfaceCard(
              child: Column(
                children: [
                  for (var i = 0;
                      i < items.length;
                      i++) ...[
                    _SubtaskRow(
                      subtask: items[i],
                    ),
                    if (i < items.length - 1)
                      const Divider(
                        height: 20,
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddSubtask(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller =
        TextEditingController();

    final result =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 +
                MediaQuery.viewInsetsOf(
                  context,
                ).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration:
                      const InputDecoration(
                    hintText: 'New subtask',
                  ),
                  onSubmitted: (value) {
                    Navigator.pop(
                      context,
                      value,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () {
                  Navigator.pop(
                    context,
                    controller.text,
                  );
                },
                icon: const Icon(
                  Icons.add_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (result == null ||
        result.trim().isEmpty) {
      return;
    }

    await ref
        .read(subtaskRepositoryProvider)
        .create(
          taskId: taskId,
          title: result,
        );
  }
}

class _SubtaskRow extends ConsumerWidget {
  const _SubtaskRow({
    required this.subtask,
  });

  final Subtask subtask;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      children: [
        Checkbox(
          value: subtask.isCompleted,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            ref
                .read(
                  subtaskRepositoryProvider,
                )
                .setCompleted(
                  subtask.id,
                  completed: value,
                );
          },
        ),
        Expanded(
          child: Text(
            subtask.title,
            style: TextStyle(
              decoration: subtask.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Delete subtask',
          onPressed: () {
            ref
                .read(
                  subtaskRepositoryProvider,
                )
                .delete(subtask.id);
          },
          icon: const Icon(
            Icons.close_rounded,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _AttachmentSection extends ConsumerWidget {
  const _AttachmentSection({
    required this.taskId,
  });

  final String taskId;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final attachments = ref.watch(
      attachmentsProvider(taskId),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Attachments',
                style: theme.textTheme.titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add attachment',
              onPressed: () {
                showAddAttachmentSheet(
                  context: context,
                  ref: ref,
                  taskId: taskId,
                );
              },
              icon: const Icon(
                Icons.attach_file_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        attachments.when(
          loading: () =>
              const LinearProgressIndicator(),
          error: (error, stack) =>
              Text('$error'),
          data: (items) {
            if (items.isEmpty) {
              return Text(
                'No attachments',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(
                  color: theme.colorScheme
                      .onSurfaceVariant,
                ),
              );
            }

            return Column(
              children: [
                for (final attachment
                    in items) ...[
                  _AttachmentTile(
                    attachment: attachment,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile
    extends ConsumerWidget {
  const _AttachmentTile({
    required this.attachment,
  });

  final Attachment attachment;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final repository = ref.read(
      attachmentRepositoryProvider,
    );

    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              _openAttachment(
            context,
            ref,
          ),
          child: Padding(
            padding:
                const EdgeInsets.all(
              14,
            ),
            child: Row(
              children: [
                Hero(
                  tag:
                      'attachment-${attachment.id}',
                  child:
                      FutureBuilder<File>(
                    future: repository
                        .resolveFile(
                      attachment,
                    ),
                    builder:
                        (context,
                            snapshot) {
                      if (attachment.type ==
                              AttachmentType
                                  .image &&
                          snapshot.hasData) {
                        return ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                          child: Image.file(
                            snapshot.data!,
                            width: 52,
                            height: 52,
                            fit:
                                BoxFit.cover,
                            cacheWidth:
                                160,
                          ),
                        );
                      }

                      return Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          switch (
                              attachment
                                  .type) {
                            AttachmentType
                                    .image =>
                              Icons
                                  .image_outlined,
                            AttachmentType
                                    .video =>
                              Icons
                                  .play_circle_outline_rounded,
                            AttachmentType
                                    .file =>
                              Icons
                                  .description_outlined,
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        attachment
                            .originalName,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _formatBytes(
                          attachment.size,
                        ),
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                          color: Theme.of(
                            context,
                          )
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip:
                      'Attachment actions',
                  onSelected:
                      (action) async {
                    switch (action) {
                      case 'open':
                        await _openAttachment(
                          context,
                          ref,
                        );

                      case 'share':
                        try {
                          await ref
                              .read(
                                attachmentActionServiceProvider,
                              )
                              .share(
                                attachment,
                              );
                        } catch (error) {
                          if (context
                              .mounted) {
                            ScaffoldMessenger
                                    .of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content:
                                    Text(
                                  'Could not share attachment: $error',
                                ),
                              ),
                            );
                          }
                        }

                      case 'delete':
                        final confirmed =
                            await showDialog<
                                bool>(
                          context:
                              context,
                          builder:
                              (context) {
                            return AlertDialog(
                              title:
                                  const Text(
                                'Delete attachment?',
                              ),
                              content:
                                  Text(
                                '"${attachment.originalName}" will be removed from this task and local storage.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () {
                                    Navigator.pop(
                                      context,
                                      false,
                                    );
                                  },
                                  child:
                                      const Text(
                                    'Cancel',
                                  ),
                                ),
                                FilledButton(
                                  onPressed:
                                      () {
                                    Navigator.pop(
                                      context,
                                      true,
                                    );
                                  },
                                  child:
                                      const Text(
                                    'Delete',
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed ==
                            true) {
                          await repository
                              .delete(
                            attachment.id,
                          );
                        }
                    }
                  },
                  itemBuilder:
                      (_) => const [
                    PopupMenuItem(
                      value: 'open',
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons
                              .open_in_new_rounded,
                        ),
                        title:
                            Text('Open'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons
                              .share_outlined,
                        ),
                        title:
                            Text('Share'),
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        leading: Icon(
                          Icons
                              .delete_outline_rounded,
                        ),
                        title:
                            Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (attachment.type ==
        AttachmentType.file) {
      final result = await ref
          .read(
            attachmentActionServiceProvider,
          )
          .openExternal(
            attachment,
          );

      if (!result.success &&
          context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              result.message ??
                  'Could not open file.',
            ),
          ),
        );
      }

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AttachmentViewerScreen(
          attachment: attachment,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;

    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }

    final mb = kb / 1024;

    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }

    final gb = mb / 1024;

    return '${gb.toStringAsFixed(2)} GB';
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLow,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
  });

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) =
        switch (priority) {
      TaskPriority.low => (
          'Low',
          AppColors.info,
        ),
      TaskPriority.medium => (
          'Medium',
          AppColors.warning,
        ),
      TaskPriority.high => (
          'High',
          AppColors.danger,
        ),
      TaskPriority.critical => (
          'Critical',
          AppColors.danger,
        ),
      TaskPriority.none => (
          '',
          Colors.transparent,
        ),
    };

    return Chip(
      avatar: Icon(
        Icons.flag_rounded,
        size: 16,
        color: color,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color,
        ),
      ),
    );
  }
}


Set<int> _decodeRecurrenceWeekdays(
  String? value,
) {
  if (value == null || value.isEmpty) {
    return {};
  }

  try {
    final decoded = jsonDecode(value);

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
