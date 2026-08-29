import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/tasks/providers/task_providers.dart';
import '../features/tasks/providers/task_query_providers.dart';
import '../features/trash/providers/trash_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class FlowTaskApp
    extends ConsumerStatefulWidget {
  const FlowTaskApp({
    super.key,
  });

  @override
  ConsumerState<FlowTaskApp>
      createState() =>
          _FlowTaskAppState();
}

class _FlowTaskAppState
    extends ConsumerState<FlowTaskApp> {
  late final AppLifecycleListener
      _lifecycleListener;

  @override
  void initState() {
    super.initState();

    _lifecycleListener =
        AppLifecycleListener(
      onResume:
          _refreshExternalChanges,
    );
  }

  void _refreshExternalChanges() {
    ref.invalidate(
      todayTasksProvider,
    );
    ref.invalidate(
      overdueTasksProvider,
    );
    ref.invalidate(
      allTasksProvider,
    );
    ref.invalidate(
      completedTasksProvider,
    );
    ref.invalidate(
      taskProvider,
    );
    ref.invalidate(
      remindersProvider,
    );
    ref.invalidate(
      recurrenceProvider,
    );
    ref.invalidate(
      filteredTasksProvider,
    );
    ref.invalidate(
      trashTasksProvider,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode =
        ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FlowTask',
      debugShowCheckedModeBanner:
          false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          themeMode.valueOrNull ??
              ThemeMode.system,
      routerConfig: router,
    );
  }
}
