import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/projects/ui/project_detail_screen.dart';
import '../features/projects/ui/projects_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../features/tasks/ui/task_detail_screen.dart';
import '../features/tasks/ui/task_editor_screen.dart';
import '../features/tasks/ui/task_list_screen.dart';
import '../features/tags/ui/tag_management_screen.dart';
import '../features/today/ui/today_screen.dart';
import '../features/trash/ui/trash_screen.dart';
import '../shared/widgets/app_scaffold.dart';
import '../core/widget/flowtask_widget_link.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _todayNavigatorKey = GlobalKey<NavigatorState>();

final _tasksNavigatorKey = GlobalKey<NavigatorState>();

final _projectsNavigatorKey = GlobalKey<NavigatorState>();

final _settingsNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/today',
  redirect: (context, state) {
    final normalized = FlowTaskWidgetLink.normalizeLocation(
      state.uri.toString(),
    );
    if (normalized == null || normalized == state.uri.toString()) {
      return null;
    }
    return normalized;
  },
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _todayNavigatorKey,
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) {
                return const TodayScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _tasksNavigatorKey,
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) {
                return const TaskListScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _projectsNavigatorKey,
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) {
                return const ProjectsScreen();
              },
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                return const SettingsScreen();
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/task/new',
      builder: (context, state) {
        return TaskEditorScreen(
          initialProjectId: state.uri.queryParameters['projectId'],
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/task/:id',
      builder: (context, state) {
        return TaskDetailScreen(taskId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/task/:id/edit',
      builder: (context, state) {
        return TaskEditorScreen(taskId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/project/:id',
      builder: (context, state) {
        return ProjectDetailScreen(projectId: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/trash',
      builder: (context, state) {
        return const TrashScreen();
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/tags',
      builder: (context, state) {
        return const TagManagementScreen();
      },
    ),
  ],
);
