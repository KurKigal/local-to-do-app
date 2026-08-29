import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/database/tables/tasks.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onCompletedChanged,
    this.onTap,
    super.key,
  });

  final Task task;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final completed =
        task.status == TaskStatus.completed;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskCheckbox(
                checked: completed,
                onChanged: onCompletedChanged,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: completed
                                  ? colorScheme
                                      .onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),

                        if (task.dueAt != null) ...[
                          const SizedBox(width: 12),
                          _DueLabel(task: task),
                        ],
                      ],
                    ),

                    if (task.description != null) ...[
                      const SizedBox(height: 6),

                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          color:
                              colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    if (task.priority !=
                        TaskPriority.none) ...[
                      const SizedBox(height: 10),

                      _PriorityBadge(
                        priority: task.priority,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  const _TaskCheckbox({
    required this.checked,
    required this.onChanged,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkResponse(
      radius: 24,
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked
              ? AppColors.success
              : Colors.transparent,
          border: Border.all(
            color: checked
                ? AppColors.success
                : colorScheme.outlineVariant,
            width: 1.6,
          ),
        ),
        child: checked
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _DueLabel extends StatelessWidget {
  const _DueLabel({
    required this.task,
  });

  final Task task;

  @override
  Widget build(BuildContext context) {
    final dueAt = task.dueAt!;

    final theme = Theme.of(context);

    final text = task.hasDueTime
        ? DateFormat('HH:mm').format(dueAt)
        : DateFormat('MMM d').format(dueAt);

    final now = DateTime.now();

    final overdue = task.status != TaskStatus.completed &&
        (task.hasDueTime
            ? dueAt.isBefore(now)
            : DateTime(
                dueAt.year,
                dueAt.month,
                dueAt.day,
              ).isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ),
              ));

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: overdue
            ? AppColors.danger
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.priority,
  });

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}