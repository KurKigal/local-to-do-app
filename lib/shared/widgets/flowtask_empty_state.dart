import 'package:flutter/material.dart';

class FlowTaskEmptyState
    extends StatelessWidget {
  const FlowTaskEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              width: 68,
              height: 68,
              decoration:
                  BoxDecoration(
                color: theme
                    .colorScheme
                    .primaryContainer
                    .withValues(
                      alpha: 0.42,
                    ),
                shape:
                    BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: theme
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign:
                  TextAlign.center,
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
              message,
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
            if (actionLabel != null &&
                onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                    Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
