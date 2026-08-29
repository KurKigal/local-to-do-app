import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/tasks/ui/widgets/quick_add_task_sheet.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation:
          index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,

      extendBody: true,

      floatingActionButton: GestureDetector(
        onLongPress: () {
          context.push('/task/new');
        },
        child: FloatingActionButton(
          heroTag: 'main_add_task',
          onPressed: () {
            showQuickAddTaskSheet(context);
          },
          child: const Icon(
            Icons.add_rounded,
            size: 30,
          ),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: _NavigationBar(
        currentIndex: navigationShell.currentIndex,
        onSelected: _goBranch,
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface
            .withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant
                .withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.today_outlined,
                  selectedIcon: Icons.today_rounded,
                  label: 'Today',
                  selected: currentIndex == 0,
                  onTap: () => onSelected(0),
                ),
              ),

              Expanded(
                child: _NavItem(
                  icon: Icons.checklist_outlined,
                  selectedIcon: Icons.checklist_rounded,
                  label: 'Tasks',
                  selected: currentIndex == 1,
                  onTap: () => onSelected(1),
                ),
              ),

              const SizedBox(width: 68),

              Expanded(
                child: _NavItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder_rounded,
                  label: 'Projects',
                  selected: currentIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ),

              Expanded(
                child: _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                  selected: currentIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              selected ? selectedIcon : icon,
              key: ValueKey(selected),
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style:
                theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}