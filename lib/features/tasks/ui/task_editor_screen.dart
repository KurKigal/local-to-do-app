import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tasks.dart';
import '../../organization/providers/organization_providers.dart';
import '../models/recurrence_rule.dart';
import '../providers/task_providers.dart';
import 'widgets/project_picker_sheet.dart';
import 'widgets/recurrence_editor_sheet.dart';
import 'widgets/tag_picker_sheet.dart';

class TaskEditorScreen extends ConsumerWidget {
  const TaskEditorScreen({
    this.taskId,
    this.initialProjectId,
    super.key,
  });

  final String? taskId;
  final String? initialProjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (taskId == null) {
      return _TaskEditorForm(
        initialProjectId: initialProjectId,
      );
    }

    final task = ref.watch(
      taskProvider(taskId!),
    );

    return task.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Could not load task:\n$error',
            textAlign: TextAlign.center,
          ),
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

        return _TaskEditorForm(
          key: ValueKey(task.id),
          task: task,
        );
      },
    );
  }
}

class _TaskEditorForm
    extends ConsumerStatefulWidget {
  const _TaskEditorForm({
    this.task,
    this.initialProjectId,
    super.key,
  });

  final Task? task;
  final String? initialProjectId;

  @override
  ConsumerState<_TaskEditorForm> createState() =>
      _TaskEditorFormState();
}

class _TaskEditorFormState
    extends ConsumerState<_TaskEditorForm> {
  late final TextEditingController
      _titleController;
  late final TextEditingController
      _descriptionController;

  late TaskPriority _priority;

  DateTime? _dueAt;
  bool _hasDueTime = false;

  String? _projectId;
  Set<String> _selectedTagIds = {};

  RecurrenceRuleDraft? _recurrence;

  bool _tagsLoaded = false;
  bool _recurrenceLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController =
        TextEditingController(
      text: task?.title ?? '',
    );

    _descriptionController =
        TextEditingController(
      text: task?.description ?? '',
    );

    _priority =
        task?.priority ??
            TaskPriority.none;

    _dueAt = task?.dueAt;
    _hasDueTime =
        task?.hasDueTime ?? false;
    _projectId =
        task?.projectId ??
            widget.initialProjectId;

    if (task == null) {
      _tagsLoaded = true;
      _recurrenceLoaded = true;
    } else {
      _loadTaskRelations(task.id);
    }
  }

  Future<void> _loadTaskRelations(
    String taskId,
  ) async {
    final results = await Future.wait([
      ref
          .read(tagRepositoryProvider)
          .getForTask(taskId),
      ref
          .read(
            recurrenceRepositoryProvider,
          )
          .getDraftForTask(taskId),
    ]);

    if (!mounted) {
      return;
    }

    final tags =
        results[0] as List<Tag>;
    final recurrence =
        results[1]
            as RecurrenceRuleDraft?;

    setState(() {
      _selectedTagIds =
          tags.map((tag) => tag.id).toSet();
      _recurrence = recurrence;
      _tagsLoaded = true;
      _recurrenceLoaded = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);
    final editing =
        widget.task != null;

    final projectAsync =
        _projectId == null
            ? null
            : ref.watch(
                projectProvider(
                  _projectId!,
                ),
              );

    final allTags =
        ref.watch(allTagsProvider);

    final projectName =
        projectAsync
            ?.valueOrNull
            ?.name;

    final selectedTagNames =
        allTags.valueOrNull
                ?.where(
                  (tag) =>
                      _selectedTagIds
                          .contains(
                    tag.id,
                  ),
                )
                .map(
                  (tag) => tag.name,
                )
                .toList() ??
            const <String>[];

    final ready =
        _tagsLoaded &&
            _recurrenceLoaded;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit task'
              : 'New task',
        ),
        actions: [
          TextButton(
            onPressed:
                _saving || !ready
                    ? null
                    : _save,
            child:
                const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          100,
        ),
        children: [
          TextField(
            controller:
                _titleController,
            autofocus: !editing,
            textCapitalization:
                TextCapitalization
                    .sentences,
            style: theme
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
            decoration:
                const InputDecoration(
              hintText: 'Task title',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller:
                _descriptionController,
            maxLines: 6,
            minLines: 3,
            textCapitalization:
                TextCapitalization
                    .sentences,
            decoration:
                const InputDecoration(
              hintText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle(
            title: 'Organization',
          ),
          const SizedBox(height: 12),
          _EditorTile(
            icon: Icons.folder_outlined,
            title: 'Project',
            value:
                projectName ??
                    'No project',
            onTap: _pickProject,
          ),
          const SizedBox(height: 10),
          _EditorTile(
            icon: Icons.sell_outlined,
            title: 'Tags',
            value:
                selectedTagNames
                        .isEmpty
                    ? 'No tags'
                    : selectedTagNames
                        .join(', '),
            onTap: _pickTags,
          ),
          const SizedBox(height: 28),
          const _SectionTitle(
            title: 'Schedule',
          ),
          const SizedBox(height: 12),
          _EditorTile(
            icon: Icons
                .calendar_today_outlined,
            title: 'Date',
            value: _dueAt == null
                ? 'No date'
                : DateFormat(
                    'EEE, d MMM yyyy',
                  ).format(_dueAt!),
            onTap: _pickDate,
          ),
          const SizedBox(height: 10),
          _EditorTile(
            icon:
                Icons.schedule_outlined,
            title: 'Time',
            value:
                _dueAt != null &&
                        _hasDueTime
                    ? DateFormat(
                        'HH:mm',
                      ).format(_dueAt!)
                    : 'No time',
            onTap: _pickTime,
          ),
          const SizedBox(height: 10),
          _EditorTile(
            icon:
                Icons.repeat_rounded,
            title: 'Repeat',
            value:
                recurrenceRuleLabel(
              _recurrence,
            ),
            onTap: _pickRecurrence,
          ),
          if (_dueAt != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment:
                  Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _dueAt = null;
                    _hasDueTime =
                        false;
                    _recurrence =
                        null;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
                label: const Text(
                  'Clear date',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Priority',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<
              TaskPriority>(
            initialValue: _priority,
            decoration:
                const InputDecoration(
              prefixIcon: Icon(
                Icons.flag_outlined,
              ),
            ),
            items:
                TaskPriority.values.map(
              (priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(
                    _priorityName(
                      priority,
                    ),
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _priority = value;
              });
            },
          ),
        ],
      ),
    );
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

    setState(() {
      _projectId =
          result.projectId;
    });
  }

  Future<void> _pickTags() async {
    final result =
        await showTagPickerSheet(
      context: context,
      selectedTagIds:
          _selectedTagIds,
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedTagIds = result;
    });
  }

  Future<void>
      _pickRecurrence() async {
    if (_dueAt == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Choose a due date before adding a repeat rule.',
          ),
        ),
      );

      return;
    }

    final result =
        await showRecurrenceEditorSheet(
      context: context,
      initialRule: _recurrence,
      dueAt: _dueAt!,
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _recurrence = result.rule;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          _dueAt ?? now,
      firstDate: DateTime(
        now.year - 2,
      ),
      lastDate: DateTime(
        now.year + 20,
      ),
    );

    if (selected == null) {
      return;
    }

    final old = _dueAt;

    setState(() {
      if (old != null &&
          _hasDueTime) {
        _dueAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
          old.hour,
          old.minute,
        );
      } else {
        _dueAt = DateTime(
          selected.year,
          selected.month,
          selected.day,
        );
      }
    });
  }

  Future<void> _pickTime() async {
    final initial =
        TimeOfDay.fromDateTime(
      _dueAt ?? DateTime.now(),
    );

    final selected =
        await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (selected == null) {
      return;
    }

    final date =
        _dueAt ?? DateTime.now();

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        selected.hour,
        selected.minute,
      );

      _hasDueTime = true;
    });
  }

  Future<void> _save() async {
    final title =
        _titleController
            .text
            .trim();

    if (title.isEmpty ||
        _saving ||
        !_tagsLoaded ||
        !_recurrenceLoaded) {
      return;
    }

    if (_recurrence != null &&
        _dueAt == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'A repeating task needs a due date.',
          ),
        ),
      );

      return;
    }

    if (_recurrence?.endAt !=
            null &&
        _dueAt != null &&
        _recurrence!.endAt!
            .isBefore(_dueAt!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Repeat end date cannot be before the task due date.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final service =
          ref.read(
        taskServiceProvider,
      );

      final tagRepository =
          ref.read(
        tagRepositoryProvider,
      );

      final recurrenceRepository =
          ref.read(
        recurrenceRepositoryProvider,
      );

      final task =
          widget.task;

      late final String taskId;

      if (task == null) {
        taskId =
            await service.createTask(
          title: title,
          description:
              _descriptionController
                  .text,
          projectId: _projectId,
          priority: _priority,
          dueAt: _dueAt,
          hasDueTime:
              _hasDueTime,
        );
      } else {
        taskId = task.id;

        await service.updateTask(
          id: task.id,
          title: title,
          description:
              _descriptionController
                  .text,
          projectId: _projectId,
          priority: _priority,
          dueAt: _dueAt,
          hasDueTime:
              _hasDueTime,
        );
      }

      await tagRepository
          .setTagsForTask(
        taskId,
        _selectedTagIds,
      );

      await recurrenceRepository
          .saveForTask(
        taskId: taskId,
        rule: _recurrence,
      );

      if (mounted) {
        context.pop(
          task == null
              ? taskId
              : null,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _priorityName(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.none => 'None',
      TaskPriority.low => 'Low',
      TaskPriority.medium =>
        'Medium',
      TaskPriority.high => 'High',
      TaskPriority.critical =>
        'Critical',
    };
  }
}

class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EditorTile
    extends StatelessWidget {
  const _EditorTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerLow,
      borderRadius:
          BorderRadius.circular(18),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),
        leading: Icon(icon),
        title: Text(title),
        trailing:
            ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 190,
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign:
                TextAlign.end,
          ),
        ),
      ),
    );
  }
}
