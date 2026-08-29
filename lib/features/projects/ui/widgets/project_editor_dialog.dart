import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../core/database/app_database.dart';
import '../../../organization/providers/organization_providers.dart';

Future<String?> showCreateProjectDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return _showProjectEditorDialog(
    context: context,
    ref: ref,
  );
}

Future<void> showEditProjectDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Project project,
}) async {
  await _showProjectEditorDialog(
    context: context,
    ref: ref,
    project: project,
  );
}

Future<String?> _showProjectEditorDialog({
  required BuildContext context,
  required WidgetRef ref,
  Project? project,
}) async {
  final controller =
      TextEditingController(
    text: project?.name ?? '',
  );

  var selectedColor =
      project?.color == null
          ? _projectColors.first
          : Color(project!.color!);

  final result =
      await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder:
            (context, setDialogState) {
          return AlertDialog(
            title: Text(
              project == null
                  ? 'New project'
                  : 'Edit project',
            ),
            content: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                TextField(
                  controller:
                      controller,
                  autofocus: true,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Project name',
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  'Color',
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color
                        in _projectColors)
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
                              AppMotion.fast,
                          curve:
                              AppMotion.curve,
                          width: 36,
                          height: 36,
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
                                      size: 18,
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
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                child: const Text(
                  'Cancel',
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final name =
                      controller.text.trim();

                  if (name.isEmpty) {
                    return;
                  }

                  if (project == null) {
                    final id = await ref
                        .read(
                          projectRepositoryProvider,
                        )
                        .create(
                          name: name,
                          color: selectedColor
                              .toARGB32(),
                        );

                    if (context
                        .mounted) {
                      Navigator.pop(
                        context,
                        id,
                      );
                    }
                  } else {
                    await ref
                        .read(
                          projectRepositoryProvider,
                        )
                        .update(
                          id: project.id,
                          name: name,
                          icon:
                              project.icon,
                          color: selectedColor
                              .toARGB32(),
                        );

                    if (context
                        .mounted) {
                      Navigator.pop(
                        context,
                        project.id,
                      );
                    }
                  }
                },
                child: Text(
                  project == null
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

  controller.dispose();

  return result;
}

const _projectColors = [
  Color(0xFF7657FF),
  Color(0xFF4F8CFF),
  Color(0xFF00A8A8),
  Color(0xFF35C977),
  Color(0xFFFFB84D),
  Color(0xFFFF735C),
  Color(0xFFE052A0),
  Color(0xFF9B6BFF),
];
