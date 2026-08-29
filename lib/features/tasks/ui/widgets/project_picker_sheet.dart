import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/providers/organization_providers.dart';
import '../../../projects/ui/widgets/project_editor_dialog.dart';

class ProjectPickerResult {
  const ProjectPickerResult(this.projectId);

  final String? projectId;
}

Future<ProjectPickerResult?> showProjectPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String? currentProjectId,
}) {
  return showModalBottomSheet<ProjectPickerResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ProjectPickerSheet(
      currentProjectId: currentProjectId,
    ),
  );
}

class _ProjectPickerSheet extends ConsumerWidget {
  const _ProjectPickerSheet({
    required this.currentProjectId,
  });

  final String? currentProjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                12,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose project',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New project',
                    onPressed: () async {
                      final id = await showCreateProjectDialog(
                        context: context,
                        ref: ref,
                      );

                      if (id != null && context.mounted) {
                        Navigator.pop(
                          context,
                          ProjectPickerResult(id),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.create_new_folder_outlined,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const _ProjectDot(
                color: Color(0xFF8A8F9E),
              ),
              title: const Text('No project'),
              trailing: currentProjectId == null
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () {
                Navigator.pop(
                  context,
                  const ProjectPickerResult(null),
                );
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: projects.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$error'),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No projects yet. Create one with the button above.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final project = items[index];
                      final color = project.color == null
                          ? Theme.of(context).colorScheme.primary
                          : Color(project.color!);

                      return ListTile(
                        leading: _ProjectDot(
                          color: color,
                        ),
                        title: Text(project.name),
                        trailing: currentProjectId == project.id
                            ? const Icon(Icons.check_rounded)
                            : null,
                        onTap: () {
                          Navigator.pop(
                            context,
                            ProjectPickerResult(project.id),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDot extends StatelessWidget {
  const _ProjectDot({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
