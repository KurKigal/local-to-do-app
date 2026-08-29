import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/tables/tasks.dart';
import '../../../../shared/feedback/flowtask_haptics.dart';
import '../../../organization/providers/organization_providers.dart';
import '../../providers/task_providers.dart';
import 'project_picker_sheet.dart';

Future<void> showQuickAddTaskSheet(
  BuildContext context,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        const _QuickAddTaskSheet(),
  );
}

class _QuickAddTaskSheet
    extends ConsumerStatefulWidget {
  const _QuickAddTaskSheet();

  @override
  ConsumerState<_QuickAddTaskSheet>
      createState() =>
          _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState
    extends ConsumerState<
        _QuickAddTaskSheet> {
  late final TextEditingController
      _controller;

  DateTime? _dueAt;
  bool _hasDueTime = false;

  TaskPriority _priority =
      TaskPriority.none;

  String? _projectId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = _projectId == null
        ? null
        : ref.watch(
            projectProvider(
              _projectId!,
            ),
          );

    final bottomInset =
        MediaQuery.viewInsetsOf(
      context,
    ).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        18 + bottomInset,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Quick add',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller:
                      _controller,
                  autofocus: true,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  textInputAction:
                      TextInputAction.done,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'What needs to be done?',
                  ),
                  onSubmitted: (_) =>
                      _save(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed:
                    _saving
                        ? null
                        : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .arrow_upward_rounded,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection:
                Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(
                  icon: Icons
                      .calendar_today_outlined,
                  label:
                      _dueAt == null
                          ? 'Date'
                          : DateFormat(
                              _hasDueTime
                                  ? 'd MMM · HH:mm'
                                  : 'd MMM',
                            ).format(
                              _dueAt!,
                            ),
                  selected:
                      _dueAt != null,
                  onPressed:
                      _pickDate,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon:
                      Icons.flag_outlined,
                  label:
                      _priorityLabel(
                    _priority,
                  ),
                  selected:
                      _priority !=
                          TaskPriority.none,
                  onPressed:
                      _pickPriority,
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  icon:
                      Icons.folder_outlined,
                  label: project
                          ?.valueOrNull
                          ?.name ??
                      'Project',
                  selected:
                      _projectId != null,
                  onPressed:
                      _pickProject,
                ),
                if (_dueAt != null) ...[
                  const SizedBox(width: 8),
                  _QuickChip(
                    icon:
                        Icons.close_rounded,
                    label: 'Clear date',
                    selected: false,
                    onPressed: () {
                      setState(() {
                        _dueAt = null;
                        _hasDueTime =
                            false;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now =
        DateTime.now();

    final choice =
        await showModalBottomSheet<
            String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons.today_rounded,
                ),
                title:
                    const Text('Today'),
                onTap: () =>
                    Navigator.pop(
                  context,
                  'today',
                ),
              ),
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .event_outlined,
                ),
                title:
                    const Text('Tomorrow'),
                onTap: () =>
                    Navigator.pop(
                  context,
                  'tomorrow',
                ),
              ),
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .calendar_month_outlined,
                ),
                title: const Text(
                  'Pick date',
                ),
                onTap: () =>
                    Navigator.pop(
                  context,
                  'custom',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null ||
        !mounted) {
      return;
    }

    DateTime selected;

    if (choice == 'today') {
      selected = DateTime(
        now.year,
        now.month,
        now.day,
      );
    } else if (choice ==
        'tomorrow') {
      selected = DateTime(
        now.year,
        now.month,
        now.day + 1,
      );
    } else {
      final date =
          await showDatePicker(
        context: context,
        initialDate:
            _dueAt ?? now,
        firstDate: DateTime(
          now.year,
          now.month,
          now.day,
        ),
        lastDate:
            DateTime(
          now.year + 20,
        ),
      );

      if (date == null ||
          !mounted) {
        return;
      }

      selected = DateTime(
        date.year,
        date.month,
        date.day,
      );
    }

    final addTime =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Add time?'),
          content: const Text(
            'You can keep this as a date-only task or add a specific time.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Date only'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Add time'),
            ),
          ],
        );
      },
    );

    if (addTime == true &&
        mounted) {
      final time =
          await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(
          DateTime.now().add(
            const Duration(
              hours: 1,
            ),
          ),
        ),
      );

      if (time != null) {
        selected = DateTime(
          selected.year,
          selected.month,
          selected.day,
          time.hour,
          time.minute,
        );

        _hasDueTime = true;
      } else {
        _hasDueTime = false;
      }
    } else {
      _hasDueTime = false;
    }

    await FlowTaskHaptics.selection();

    if (!mounted) {
      return;
    }

    setState(() {
      _dueAt = selected;
    });
  }

  Future<void>
      _pickPriority() async {
    final result =
        await showModalBottomSheet<
            TaskPriority>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              for (final priority
                  in TaskPriority.values)
                ListTile(
                  leading: Icon(
                    priority ==
                            TaskPriority
                                .none
                        ? Icons
                            .flag_outlined
                        : Icons
                            .flag_rounded,
                  ),
                  title: Text(
                    _priorityLabel(
                      priority,
                    ),
                  ),
                  trailing:
                      priority ==
                              _priority
                          ? const Icon(
                              Icons
                                  .check_rounded,
                            )
                          : null,
                  onTap: () =>
                      Navigator.pop(
                    context,
                    priority,
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (result == null ||
        !mounted) {
      return;
    }

    await FlowTaskHaptics.selection();

    if (!mounted) {
      return;
    }

    setState(() {
      _priority = result;
    });
  }

  Future<void>
      _pickProject() async {
    final result =
        await showProjectPickerSheet(
      context: context,
      ref: ref,
      currentProjectId:
          _projectId,
    );

    if (result == null ||
        !mounted) {
      return;
    }

    await FlowTaskHaptics.selection();

    if (!mounted) {
      return;
    }

    setState(() {
      _projectId =
          result.projectId;
    });
  }

  Future<void> _save() async {
    final title =
        _controller
            .text
            .trim();

    if (title.isEmpty ||
        _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ref
          .read(
            taskServiceProvider,
          )
          .createTask(
            title: title,
            projectId:
                _projectId,
            priority: _priority,
            dueAt: _dueAt,
            hasDueTime:
                _hasDueTime,
          );

      await FlowTaskHaptics.success();

      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _priorityLabel(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.none =>
        'Priority',
      TaskPriority.low => 'Low',
      TaskPriority.medium =>
        'Medium',
      TaskPriority.high => 'High',
      TaskPriority.critical =>
        'Critical',
    };
  }
}

class _QuickChip
    extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return ActionChip(
      avatar: Icon(
        icon,
        size: 17,
      ),
      label: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 145,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
      ),
      side: BorderSide(
        color: selected
            ? scheme.primary
            : scheme.outlineVariant,
      ),
      backgroundColor:
          selected
              ? scheme
                  .primaryContainer
                  .withValues(
                    alpha: 0.45,
                  )
              : scheme
                  .surfaceContainerLow,
      onPressed: onPressed,
    );
  }
}
