import 'package:flutter/material.dart';

class FlowTaskAsyncError
    extends StatelessWidget {
  const FlowTaskAsyncError({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 40,
              color: theme
                  .colorScheme
                  .error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                    const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
