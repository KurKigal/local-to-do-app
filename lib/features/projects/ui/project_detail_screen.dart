import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/tables/tasks.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/task_tile.dart';
import '../../organization/providers/organization_providers.dart';
import '../../tasks/providers/task_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({
    required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(
      projectProvider(projectId),
    );

    final tasks = ref.watch(
      projectTasksProvider(projectId),
    );

    return project.when(
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
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Project not found'),
            ),
          );
        }

        final color = project.color == null
            ? Theme.of(context).colorScheme.primary
            : Color(project.color!);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'project_add_task',
            onPressed: () {
              context.push(
                '/task/new?projectId=${project.id}',
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
          body: tasks.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('$error'),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Project is empty',
                    description:
                        'Add a task to start filling this project.',
                  ),
                );
              }

              final open = items
                  .where(
                    (task) =>
                        task.status != TaskStatus.completed,
                  )
                  .toList();

              final completed = items
                  .where(
                    (task) =>
                        task.status == TaskStatus.completed,
                  )
                  .toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  120,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${open.length} open · ${completed.length} completed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (open.isNotEmpty) ...[
                    Text(
                      'Open',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final task in open) ...[
                      TaskTile(
                        task: task,
                        onTap: () {
                          context.push(
                            '/task/${task.id}',
                          );
                        },
                        onCompletedChanged: (completed) {
                          ref
                              .read(taskServiceProvider)
                              .setCompleted(
                                task.id,
                                completed: completed,
                              );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Completed',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final task in completed) ...[
                      TaskTile(
                        task: task,
                        onTap: () {
                          context.push(
                            '/task/${task.id}',
                          );
                        },
                        onCompletedChanged: (completed) {
                          ref
                              .read(taskServiceProvider)
                              .setCompleted(
                                task.id,
                                completed: completed,
                              );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
