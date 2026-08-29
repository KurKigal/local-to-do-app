import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/feedback/flowtask_haptics.dart';
import '../../../shared/widgets/flowtask_async_error.dart';
import '../../../shared/widgets/flowtask_empty_state.dart';

import '../../organization/providers/organization_providers.dart';
import 'widgets/project_editor_dialog.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            tooltip: 'Manage tags',
            onPressed: () async {
              await FlowTaskHaptics.selection();

              if (!context.mounted) {
                return;
              }

              context.push('/tags');
            },
            icon: const Icon(
              Icons.sell_outlined,
            ),
          ),
          IconButton(
            tooltip: 'New project',
            onPressed: () async {
              await FlowTaskHaptics.light();

              if (!context.mounted) {
                return;
              }

              showCreateProjectDialog(
                context: context,
                ref: ref,
              );
            },
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: projects.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) =>
            FlowTaskAsyncError(
          message:
              'Could not load projects.\n$error',
          onRetry: () {
            ref.invalidate(
              projectsProvider,
            );
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return FlowTaskEmptyState(
              icon:
                  Icons.folder_copy_outlined,
              title: 'No projects yet',
              message:
                  'Group related tasks into focused spaces.',
              actionLabel:
                  'Create project',
              onAction: () async {
                await FlowTaskHaptics
                    .light();

                if (context.mounted) {
                  showCreateProjectDialog(
                    context: context,
                    ref: ref,
                  );
                }
              },
            );
          }

          return GridView.builder(
            cacheExtent: 480,
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              120,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final project = items[index];
              final color = project.color == null
                  ? theme.colorScheme.primary
                  : Color(project.color!);

              return Material(
                color: theme
                    .colorScheme
                    .surfaceContainerLow,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(22),
                  onTap: () async {
                    await FlowTaskHaptics
                        .selection();

                    if (!context.mounted) {
                      return;
                    }

                    context.push(
                      '/project/${project.id}',
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.folder_rounded,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await FlowTaskHaptics.selection();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  await showEditProjectDialog(
                                    context: context,
                                    ref: ref,
                                    project: project,
                                  );

                                  return;
                                }

                                if (value != 'delete') {
                                  return;
                                }

                                final confirmed =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'Delete project?',
                                      ),
                                      content: const Text(
                                        'Tasks will be kept and moved out of this project.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              false,
                                            );
                                          },
                                          child: const Text(
                                            'Cancel',
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              true,
                                            );
                                          },
                                          child: const Text(
                                            'Delete',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmed == true) {
                                  await FlowTaskHaptics.destructive();

                                  await ref
                                      .read(
                                        projectRepositoryProvider,
                                      )
                                      .delete(project.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          project.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(
                            color: theme.colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
