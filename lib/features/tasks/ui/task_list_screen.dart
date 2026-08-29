import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/task_tile.dart';
import '../../organization/providers/organization_providers.dart';
import '../models/task_filter.dart';
import '../providers/task_providers.dart';
import '../providers/task_query_providers.dart';
import 'widgets/task_filter_sheet.dart';

class TaskListScreen
    extends ConsumerStatefulWidget {
  const TaskListScreen({
    super.key,
  });

  @override
  ConsumerState<TaskListScreen>
      createState() =>
          _TaskListScreenState();
}

class _TaskListScreenState
    extends ConsumerState<TaskListScreen> {
  late final TextEditingController
      _searchController;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _searchController =
        TextEditingController(
      text: ref.read(
        taskFilterProvider.select(
          (filter) => filter.query,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter =
        ref.watch(taskFilterProvider);

    final tasks =
        ref.watch(filteredTasksProvider);

    final projects =
        ref.watch(projectsProvider);

    final tags =
        ref.watch(allTagsProvider);

    final theme = Theme.of(context);

    final selectedProjectNames =
        projects.valueOrNull
                ?.where(
                  (project) =>
                      filter.projectIds
                          .contains(
                    project.id,
                  ),
                )
                .map(
                  (project) =>
                      project.name,
                )
                .toList() ??
            const <String>[];

    final selectedTagNames =
        tags.valueOrNull
                ?.where(
                  (tag) =>
                      filter.tagIds
                          .contains(
                    tag.id,
                  ),
                )
                .map((tag) => tag.name)
                .toList() ??
            const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Trash',
            onPressed: () {
              context.push('/trash');
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Clear filters',
            onPressed:
                _hasAnyFilter(filter)
                    ? () {
                        ref
                            .read(
                              taskFilterProvider
                                  .notifier,
                            )
                            .clearAll();

                        _searchController
                            .clear();
                      }
                    : null,
            icon: const Icon(
              Icons
                  .filter_alt_off_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              0,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText:
                  'Search tasks…',
              leading: const Icon(
                Icons.search_rounded,
              ),
              trailing: [
                if (_searchController
                    .text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchDebounce
                          ?.cancel();

                      _searchController
                          .clear();

                      ref
                          .read(
                            taskFilterProvider
                                .notifier,
                          )
                          .setQuery('');
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                _FilterButton(
                  count: filter
                      .advancedFilterCount,
                  onPressed: () =>
                      _openFilters(
                    filter,
                  ),
                ),
              ],
              onChanged: _onSearchChanged,
              elevation:
                  const WidgetStatePropertyAll(
                0,
              ),
              backgroundColor:
                  WidgetStatePropertyAll(
                theme.colorScheme
                    .surfaceContainerLow,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              scrollDirection:
                  Axis.horizontal,
              children: [
                for (final scope
                    in TaskListScope.values) ...[
                  ChoiceChip(
                    label: Text(
                      _scopeLabel(scope),
                    ),
                    selected:
                        filter.scope == scope,
                    onSelected: (_) {
                      ref
                          .read(
                            taskFilterProvider
                                .notifier,
                          )
                          .setScope(scope);
                    },
                  ),
                  if (scope !=
                      TaskListScope
                          .values.last)
                    const SizedBox(
                      width: 8,
                    ),
                ],
              ],
            ),
          ),
          if (filter.hasAdvancedFilters)
            _ActiveFilters(
              filter: filter,
              selectedProjectNames:
                  selectedProjectNames,
              selectedTagNames:
                  selectedTagNames,
              onClearAdvanced: () {
                ref
                    .read(
                      taskFilterProvider
                          .notifier,
                    )
                    .clearAdvanced();
              },
            ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.when(
              loading: () =>
                  const Center(
                child:
                    CircularProgressIndicator(),
              ),
              error: (error, stack) =>
                  Center(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child: Text(
                    'Could not load tasks:\n$error',
                    textAlign:
                        TextAlign.center,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyTasks(
                    filter: filter,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      filteredTasksProvider,
                    );
                  },
                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      120,
                    ),
                    itemCount:
                        items.length,
                    separatorBuilder:
                        (_, _) =>
                            const SizedBox(
                      height: 10,
                    ),
                    itemBuilder:
                        (context, index) {
                      final task =
                          items[index];

                      return Dismissible(
                        key: ValueKey(
                          task.id,
                        ),
                        direction:
                            DismissDirection
                                .endToStart,
                        background:
                            const SizedBox
                                .shrink(),
                        secondaryBackground:
                            Container(
                          alignment:
                              Alignment
                                  .centerRight,
                          padding:
                              const EdgeInsets
                                  .only(
                            right: 22,
                          ),
                          decoration:
                              BoxDecoration(
                            color: theme
                                .colorScheme
                                .errorContainer,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Icon(
                            Icons
                                .delete_outline_rounded,
                            color: theme
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                        confirmDismiss:
                            (_) =>
                                _confirmTrash(
                          task,
                        ),
                        onDismissed:
                            (_) {
                          ref
                              .read(
                                taskServiceProvider,
                              )
                              .moveToTrash(
                                task.id,
                              );
                        },
                        child: TaskTile(
                          task: task,
                          onTap: () {
                            context.push(
                              '/task/${task.id}',
                            );
                          },
                          onCompletedChanged:
                              (completed) {
                            ref
                                .read(
                                  taskServiceProvider,
                                )
                                .setCompleted(
                                  task.id,
                                  completed:
                                      completed,
                                );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(
    String value,
  ) {
    setState(() {});

    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 220,
      ),
      () {
        if (!mounted) {
          return;
        }

        ref
            .read(
              taskFilterProvider.notifier,
            )
            .setQuery(value);
      },
    );
  }

  Future<void> _openFilters(
    TaskFilter current,
  ) async {
    final result =
        await showTaskFilterSheet(
      context: context,
      initialFilter: current,
    );

    if (result == null ||
        !mounted) {
      return;
    }

    ref
        .read(
          taskFilterProvider.notifier,
        )
        .replace(result);
  }

  Future<bool> _confirmTrash(
    Task task,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Move to trash?',
              ),
              content: Text(
                '"${task.title}" will be moved to Trash.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child:
                      const Text('Move'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  bool _hasAnyFilter(
    TaskFilter filter,
  ) {
    return filter.query.isNotEmpty ||
        filter.scope !=
            TaskListScope.all ||
        filter.hasAdvancedFilters;
  }

  String _scopeLabel(
    TaskListScope scope,
  ) {
    return switch (scope) {
      TaskListScope.all => 'All',
      TaskListScope.today => 'Today',
      TaskListScope.upcoming =>
        'Upcoming',
      TaskListScope.overdue =>
        'Overdue',
      TaskListScope.completed =>
        'Completed',
    };
  }
}

class _FilterButton
    extends StatelessWidget {
  const _FilterButton({
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Filters',
          onPressed: onPressed,
          icon: const Icon(
            Icons.tune_rounded,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              constraints:
                  const BoxConstraints(
                minWidth: 17,
                minHeight: 17,
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              alignment:
                  Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveFilters
    extends StatelessWidget {
  const _ActiveFilters({
    required this.filter,
    required this.selectedProjectNames,
    required this.selectedTagNames,
    required this.onClearAdvanced,
  });

  final TaskFilter filter;
  final List<String>
      selectedProjectNames;
  final List<String> selectedTagNames;
  final VoidCallback onClearAdvanced;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];

    if (filter.priorities.isNotEmpty) {
      labels.add(
        '${filter.priorities.length} priority',
      );
    }

    if (selectedProjectNames.isNotEmpty) {
      labels.add(
        selectedProjectNames.length == 1
            ? selectedProjectNames.first
            : '${selectedProjectNames.length} projects',
      );
    }

    if (selectedTagNames.isNotEmpty) {
      labels.add(
        selectedTagNames.length == 1
            ? '#${selectedTagNames.first}'
            : '${selectedTagNames.length} tags',
      );
    }

    if (filter.sort !=
        TaskSort.dueDate) {
      labels.add(
        switch (filter.sort) {
          TaskSort.priority =>
            'Priority sort',
          TaskSort.newest =>
            'Newest first',
          TaskSort.oldest =>
            'Oldest first',
          TaskSort.dueDate =>
            'Due date',
        },
      );
    }

    return SizedBox(
      height: 48,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          0,
        ),
        scrollDirection:
            Axis.horizontal,
        children: [
          for (final label
              in labels) ...[
            Chip(
              label: Text(label),
              visualDensity:
                  VisualDensity.compact,
            ),
            const SizedBox(width: 6),
          ],
          ActionChip(
            avatar: const Icon(
              Icons.close_rounded,
              size: 16,
            ),
            label: const Text(
              'Clear',
            ),
            visualDensity:
                VisualDensity.compact,
            onPressed:
                onClearAdvanced,
          ),
        ],
      ),
    );
  }
}

class _EmptyTasks
    extends StatelessWidget {
  const _EmptyTasks({
    required this.filter,
  });

  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final searching =
        filter.query.trim().isNotEmpty;

    if (searching) {
      return const Center(
        child: EmptyState(
          icon:
              Icons.search_off_rounded,
          title: 'No matching tasks',
          description:
              'Try another search or clear some filters.',
        ),
      );
    }

    return Center(
      child: EmptyState(
        icon: switch (filter.scope) {
          TaskListScope.completed =>
            Icons
                .task_alt_rounded,
          TaskListScope.overdue =>
            Icons
                .schedule_rounded,
          TaskListScope.upcoming =>
            Icons
                .calendar_month_outlined,
          _ =>
            Icons
                .checklist_rounded,
        },
        title: switch (filter.scope) {
          TaskListScope.today =>
            'Nothing due today',
          TaskListScope.upcoming =>
            'Nothing upcoming',
          TaskListScope.overdue =>
            'No overdue tasks',
          TaskListScope.completed =>
            'Nothing completed yet',
          TaskListScope.all =>
            'No tasks yet',
        },
        description:
            filter.hasAdvancedFilters
                ? 'No tasks match the active filters.'
                : 'Use the + button to create a task.',
      ),
    );
  }
}
