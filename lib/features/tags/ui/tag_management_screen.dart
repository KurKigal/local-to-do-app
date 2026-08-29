import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_motion.dart';
import '../../../shared/feedback/flowtask_haptics.dart';
import '../../../shared/widgets/flowtask_async_error.dart';
import '../../../shared/widgets/flowtask_empty_state.dart';
import '../../../core/database/app_database.dart';
import '../../organization/providers/organization_providers.dart';

class TagManagementScreen
    extends ConsumerWidget {
  const TagManagementScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final tags =
        ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Tags'),
        actions: [
          IconButton(
            tooltip: 'New tag',
            onPressed: () async {
              await FlowTaskHaptics.light();

              if (!context.mounted) {
                return;
              }

              _showTagEditor(
                context: context,
                ref: ref,
              );
            },
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: tags.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),
        error: (error, stack) =>
            FlowTaskAsyncError(
          message:
              'Could not load tags.\n$error',
          onRetry: () {
            ref.invalidate(
              allTagsProvider,
            );
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return FlowTaskEmptyState(
              icon: Icons.sell_outlined,
              title: 'No tags yet',
              message:
                  'Tags make cross-project filtering much faster.',
              actionLabel: 'Create tag',
              onAction: () async {
                await FlowTaskHaptics.light();

                if (context.mounted) {
                  _showTagEditor(
                    context: context,
                    ref: ref,
                  );
                }
              },
            );
          }

          return ListView.separated(
            cacheExtent: 520,
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              100,
            ),
            itemCount: items.length,
            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              height: 8,
            ),
            itemBuilder:
                (context, index) {
              final tag =
                  items[index];

              final color =
                  tag.color == null
                      ? Theme.of(
                          context,
                        )
                            .colorScheme
                            .secondary
                      : Color(
                          tag.color!,
                        );

              return Material(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                child: ListTile(
                  leading:
                      AnimatedContainer(
                    duration:
                        AppMotion.resolve(
                      context,
                      AppMotion.fast,
                    ),
                    width: 14,
                    height: 14,
                    decoration:
                        BoxDecoration(
                      color: color,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    tag.name,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                  trailing:
                      PopupMenuButton<
                          String>(
                    onSelected:
                        (value) async {
                      switch (value) {
                        case 'edit':
                          await FlowTaskHaptics.selection();

                          if (!context.mounted) {
                            return;
                          }

                          await _showTagEditor(
                            context:
                                context,
                            ref: ref,
                            tag: tag,
                          );

                        case 'delete':
                          final confirmed =
                              await _confirmDelete(
                            context,
                            tag,
                          );

                          if (confirmed) {
                            await FlowTaskHaptics.destructive();

                            await ref
                                .read(
                                  tagRepositoryProvider,
                                )
                                .delete(
                                  tag.id,
                                );
                          }
                      }
                    },
                    itemBuilder:
                        (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child:
                            Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await FlowTaskHaptics.selection();

                    if (!context.mounted) {
                      return;
                    }

                    _showTagEditor(
                      context: context,
                      ref: ref,
                      tag: tag,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _showTagEditor({
  required BuildContext context,
  required WidgetRef ref,
  Tag? tag,
}) async {
  final controller =
      TextEditingController(
    text: tag?.name ?? '',
  );

  var selectedColor =
      tag?.color == null
          ? _tagColors.first
          : Color(tag!.color!);

  try {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: Text(
                tag == null
                    ? 'New tag'
                    : 'Edit tag',
              ),
              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  TextField(
                    controller:
                        controller,
                    autofocus: true,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Tag name',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color
                          in _tagColors)
                        InkWell(
                          onTap: () {
                            setDialogState(
                              () {
                                selectedColor =
                                    color;
                              },
                            );
                          },
                          borderRadius:
                              BorderRadius
                                  .circular(
                            30,
                          ),
                          child:
                              AnimatedContainer(
                            duration:
                                AppMotion.resolve(
                              context,
                              AppMotion.fast,
                            ),
                            width: 34,
                            height: 34,
                            decoration:
                                BoxDecoration(
                              color: color,
                              shape:
                                  BoxShape.circle,
                              border:
                                  selectedColor ==
                                          color
                                      ? Border.all(
                                          color: Theme.of(
                                            context,
                                          )
                                              .colorScheme
                                              .onSurface,
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: Colors
                                              .transparent,
                                          width: 3,
                                        ),
                            ),
                            child:
                                selectedColor ==
                                        color
                                    ? const Icon(
                                        Icons
                                            .check_rounded,
                                        size: 17,
                                        color: Colors
                                            .white,
                                      )
                                    : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final name =
                        controller
                            .text
                            .trim();

                    if (name.isEmpty) {
                      return;
                    }

                    try {
                      if (tag == null) {
                        await ref
                            .read(
                              tagRepositoryProvider,
                            )
                            .create(
                              name: name,
                              color:
                                  selectedColor
                                      .toARGB32(),
                            );
                      } else {
                        await ref
                            .read(
                              tagRepositoryProvider,
                            )
                            .update(
                              id: tag.id,
                              name: name,
                              color:
                                  selectedColor
                                      .toARGB32(),
                            );
                      }

                      if (context
                          .mounted) {
                        Navigator.pop(
                          context,
                        );
                      }
                    } catch (error) {
                      if (context
                          .mounted) {
                        ScaffoldMessenger
                                .of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$error',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    tag == null
                        ? 'Create'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool> _confirmDelete(
  BuildContext context,
  Tag tag,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:
                const Text('Delete tag?'),
            content: Text(
              '"${tag.name}" will be removed from every task. Tasks themselves will not be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  false,
                ),
                child:
                    const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  true,
                ),
                child:
                    const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
}

const _tagColors = [
  Color(0xFF7657FF),
  Color(0xFF4F8CFF),
  Color(0xFF00A8A8),
  Color(0xFF35C977),
  Color(0xFFFFB84D),
  Color(0xFFFF735C),
  Color(0xFFE052A0),
  Color(0xFF9B6BFF),
];
