import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../providers/trash_providers.dart';

class TrashScreen
    extends ConsumerWidget {
  const TrashScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final tasks =
        ref.watch(trashTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          tasks.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Empty trash',
                    onPressed: () =>
                        _emptyTrash(
                      context,
                      ref,
                      items.length,
                    ),
                    icon: const Icon(
                      Icons
                          .delete_sweep_outlined,
                    ),
                  ),
            orElse: () =>
                const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tasks.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Text(
              'Could not load Trash:\n$error',
              textAlign:
                  TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyTrash();
          }

          return ListView.separated(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              80,
            ),
            itemCount: items.length,
            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              height: 10,
            ),
            itemBuilder:
                (context, index) {
              final task =
                  items[index];

              return _TrashTaskCard(
                task: task,
                onRestore: () async {
                  await ref
                      .read(
                        trashServiceProvider,
                      )
                      .restore(
                        task.id,
                      );

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        '"${task.title}" restored',
                      ),
                    ),
                  );
                },
                onDeleteForever:
                    () async {
                  final confirmed =
                      await _confirmDeleteForever(
                    context,
                    task,
                  );

                  if (!confirmed) {
                    return;
                  }

                  await ref
                      .read(
                        trashServiceProvider,
                      )
                      .deleteForever(
                        task.id,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _emptyTrash(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_forever_outlined,
          ),
          title:
              const Text('Empty trash?'),
          content: Text(
            '$count task${count == 1 ? '' : 's'} and their local attachments will be permanently deleted. This cannot be undone.',
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
                  const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await ref
        .read(trashServiceProvider)
        .emptyTrash();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$deleted task${deleted == 1 ? '' : 's'} permanently deleted',
        ),
      ),
    );
  }
}

class _TrashTaskCard
    extends StatelessWidget {
  const _TrashTaskCard({
    required this.task,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final Task task;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final deletedAt =
        task.deletedAt;

    return Material(
      color: theme
          .colorScheme
          .surfaceContainerLow,
      borderRadius:
          BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(
                    color: theme
                        .colorScheme
                        .errorContainer
                        .withValues(
                          alpha: 0.65,
                        ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
                      ),
                      if (deletedAt !=
                          null) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Deleted ${DateFormat('d MMM · HH:mm').format(deletedAt)}',
                          style: theme
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        onRestore,
                    icon: const Icon(
                      Icons
                          .restore_rounded,
                    ),
                    label: const Text(
                      'Restore',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      FilledButton.tonalIcon(
                    onPressed:
                        onDeleteForever,
                    icon: const Icon(
                      Icons
                          .delete_forever_outlined,
                    ),
                    label: const Text(
                      'Delete',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTrash
    extends StatelessWidget {
  const _EmptyTrash();

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(36),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
                  BoxDecoration(
                color: theme
                    .colorScheme
                    .surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons
                    .delete_outline_rounded,
                size: 32,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Trash is empty',
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks you move to Trash will appear here until you permanently delete or restore them.',
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteForever(
  BuildContext context,
  Task task,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons
                  .delete_forever_outlined,
            ),
            title: const Text(
              'Delete forever?',
            ),
            content: Text(
              '"${task.title}" and its local attachments will be permanently deleted.',
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
                    const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
}
