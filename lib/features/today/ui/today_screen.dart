import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/task_tile.dart';
import '../../tasks/providers/task_providers.dart';
import 'package:go_router/go_router.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayTasksProvider);
    final overdue = ref.watch(overdueTasksProvider);

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  todayCount:
                      today.valueOrNull?.length ?? 0,
                  overdueCount:
                      overdue.valueOrNull?.length ?? 0,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Today',
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            _TaskSection(
              tasks: today,
              emptyTitle: 'Nothing planned',
              emptyDescription:
                  'Your day is clear. Enjoy it or add something new.',
              ref: ref,
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Overdue',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if ((overdue.valueOrNull?.length ??
                            0) >
                        0) ...[
                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${overdue.valueOrNull!.length}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            _TaskSection(
              tasks: overdue,
              emptyTitle: 'All caught up',
              emptyDescription:
                  'No overdue tasks.',
              ref: ref,
              compactEmpty: true,
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.todayCount,
    required this.overdueCount,
  });

  final int todayCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          DateFormat('EEEE, d MMMM').format(now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '$todayCount',
                label: 'Tasks',
                icon: Icons.checklist_rounded,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _StatCard(
                value: '$overdueCount',
                label: 'Overdue',
                icon: Icons.schedule_rounded,
                color: overdueCount > 0
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style:
                    theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.tasks,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.ref,
    this.compactEmpty = false,
  });

  final AsyncValue<List<Task>> tasks;
  final String emptyTitle;
  final String emptyDescription;
  final WidgetRef ref;
  final bool compactEmpty;

  @override
  Widget build(BuildContext context) {
    return tasks.when(
      loading: () => const SliverPadding(
        padding: EdgeInsets.all(32),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      error: (error, stackTrace) => SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Could not load tasks: $error',
          ),
        ),
      ),

      data: (items) {
        if (items.isEmpty) {
          if (compactEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            );
          }

          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: emptyTitle,
              description: emptyDescription,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = items[index];

              return TaskTile(
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
              );
            },
          ),
        );
      },
    );
  }
}