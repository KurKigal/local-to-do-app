import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/tables/tasks.dart';
import '../../../organization/providers/organization_providers.dart';
import '../../models/task_filter.dart';

Future<TaskFilter?> showTaskFilterSheet({
  required BuildContext context,
  required TaskFilter initialFilter,
}) {
  return showModalBottomSheet<TaskFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TaskFilterSheet(
      initialFilter: initialFilter,
    ),
  );
}

class _TaskFilterSheet
    extends ConsumerStatefulWidget {
  const _TaskFilterSheet({
    required this.initialFilter,
  });

  final TaskFilter initialFilter;

  @override
  ConsumerState<_TaskFilterSheet>
      createState() =>
          _TaskFilterSheetState();
}

class _TaskFilterSheetState
    extends ConsumerState<_TaskFilterSheet> {
  late Set<TaskPriority> _priorities;
  late Set<String> _projectIds;
  late Set<String> _tagIds;
  late TaskSort _sort;

  @override
  void initState() {
    super.initState();

    _priorities = {
      ...widget.initialFilter.priorities,
    };
    _projectIds = {
      ...widget.initialFilter.projectIds,
    };
    _tagIds = {
      ...widget.initialFilter.tagIds,
    };
    _sort = widget.initialFilter.sort;
  }

  @override
  Widget build(BuildContext context) {
    final projects =
        ref.watch(projectsProvider);
    final tags =
        ref.watch(allTagsProvider);
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              12,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter tasks',
                    style: theme
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: const Text(
                    'Reset',
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
                24,
              ),
              children: [
                const _SectionLabel(
                  'Priority',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final priority
                        in TaskPriority.values)
                      if (priority !=
                          TaskPriority.none)
                        FilterChip(
                          label: Text(
                            _priorityLabel(
                              priority,
                            ),
                          ),
                          selected:
                              _priorities
                                  .contains(
                            priority,
                          ),
                          onSelected:
                              (selected) {
                            setState(() {
                              if (selected) {
                                _priorities.add(
                                  priority,
                                );
                              } else {
                                _priorities
                                    .remove(
                                  priority,
                                );
                              }
                            });
                          },
                        ),
                  ],
                ),
                const SizedBox(height: 28),
                const _SectionLabel(
                  'Projects',
                ),
                const SizedBox(height: 10),
                projects.when(
                  loading: () =>
                      const LinearProgressIndicator(),
                  error: (error, stack) =>
                      Text('$error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'No projects',
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final project
                            in items)
                          FilterChip(
                            avatar: Icon(
                              Icons.folder_rounded,
                              size: 17,
                              color:
                                  project.color ==
                                          null
                                      ? null
                                      : Color(
                                          project
                                              .color!,
                                        ),
                            ),
                            label: Text(
                              project.name,
                            ),
                            selected:
                                _projectIds
                                    .contains(
                              project.id,
                            ),
                            onSelected:
                                (selected) {
                              setState(() {
                                if (selected) {
                                  _projectIds.add(
                                    project.id,
                                  );
                                } else {
                                  _projectIds
                                      .remove(
                                    project.id,
                                  );
                                }
                              });
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const _SectionLabel(
                  'Tags',
                ),
                const SizedBox(height: 10),
                tags.when(
                  loading: () =>
                      const LinearProgressIndicator(),
                  error: (error, stack) =>
                      Text('$error'),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text(
                        'No tags',
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag
                            in items)
                          FilterChip(
                            avatar: Icon(
                              Icons.sell_outlined,
                              size: 16,
                              color:
                                  tag.color == null
                                      ? null
                                      : Color(
                                          tag.color!,
                                        ),
                            ),
                            label: Text(
                              tag.name,
                            ),
                            selected:
                                _tagIds.contains(
                              tag.id,
                            ),
                            onSelected:
                                (selected) {
                              setState(() {
                                if (selected) {
                                  _tagIds.add(
                                    tag.id,
                                  );
                                } else {
                                  _tagIds.remove(
                                    tag.id,
                                  );
                                }
                              });
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const _SectionLabel(
                  'Sort by',
                ),
                const SizedBox(height: 10),
                RadioGroup<TaskSort>(
                  groupValue: _sort,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _sort = value;
                    });
                  },
                  child: const Column(
                    children: [
                      RadioListTile<TaskSort>(
                        value:
                            TaskSort.dueDate,
                        title:
                            Text('Due date'),
                        secondary: Icon(
                          Icons
                              .calendar_today_outlined,
                        ),
                      ),
                      RadioListTile<TaskSort>(
                        value:
                            TaskSort.priority,
                        title:
                            Text('Priority'),
                        secondary: Icon(
                          Icons.flag_outlined,
                        ),
                      ),
                      RadioListTile<TaskSort>(
                        value:
                            TaskSort.newest,
                        title:
                            Text('Newest first'),
                        secondary: Icon(
                          Icons
                              .arrow_downward_rounded,
                        ),
                      ),
                      RadioListTile<TaskSort>(
                        value:
                            TaskSort.oldest,
                        title:
                            Text('Oldest first'),
                        secondary: Icon(
                          Icons
                              .arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
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
                onPressed: _apply,
                icon: const Icon(
                  Icons.check_rounded,
                ),
                label: const Text(
                  'Apply filters',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reset() {
    setState(() {
      _priorities = {};
      _projectIds = {};
      _tagIds = {};
      _sort = TaskSort.dueDate;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initialFilter.copyWith(
        priorities: {..._priorities},
        projectIds: {..._projectIds},
        tagIds: {..._tagIds},
        sort: _sort,
      ),
    );
  }

  String _priorityLabel(
    TaskPriority priority,
  ) {
    return switch (priority) {
      TaskPriority.none => 'None',
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
      TaskPriority.high => 'High',
      TaskPriority.critical => 'Critical',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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
