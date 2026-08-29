import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../organization/providers/organization_providers.dart';

Future<Set<String>?> showTagPickerSheet({
  required BuildContext context,
  required Set<String> selectedTagIds,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TagPickerSheet(
      initialSelection: selectedTagIds,
    ),
  );
}

class _TagPickerSheet extends ConsumerStatefulWidget {
  const _TagPickerSheet({
    required this.initialSelection,
  });

  final Set<String> initialSelection;

  @override
  ConsumerState<_TagPickerSheet> createState() =>
      _TagPickerSheetState();
}

class _TagPickerSheetState
    extends ConsumerState<_TagPickerSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelection};
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(allTagsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.76,
        ),
        child: Column(
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
                      'Tags',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New tag',
                    onPressed: _createTag,
                    icon: const Icon(
                      Icons.add_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tags.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('$error'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'No tags yet. Create your first tag with +.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final tag = items[index];
                      final selected =
                          _selected.contains(tag.id);
                      final color = tag.color == null
                          ? Theme.of(context)
                              .colorScheme
                              .secondary
                          : Color(tag.color!);

                      return CheckboxListTile(
                        value: selected,
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(tag.name),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selected.add(tag.id);
                            } else {
                              _selected.remove(tag.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      {..._selected},
                    );
                  },
                  child: Text(
                    _selected.isEmpty
                        ? 'Done'
                        : 'Done · ${_selected.length} selected',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New tag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Tag name',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.pop(context, value.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || !mounted) {
      return;
    }

    final id = await ref
        .read(tagRepositoryProvider)
        .create(name: name);

    if (mounted) {
      setState(() {
        _selected.add(id);
      });
    }
  }
}
