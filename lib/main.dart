import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/notifications/notification_action_handler.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_startup_recovery.dart';
import 'core/notifications/time_zone_service.dart';
import 'core/storage/attachment_lost_data_recovery.dart';
import 'core/widget/flowtask_widget_interactivity.dart';
import 'core/widget/flowtask_widget_link.dart';
import 'core/widget/flowtask_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TimeZoneService.initialize();

  await FlowTaskWidgetInteractivity.initialize();

  final initialWidgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();

  final initialTaskId = await NotificationService.instance.initialize(
    onOpenTask: (taskId) {
      router.go('/task/$taskId');
    },
    onBackgroundResponse: notificationBackgroundHandler,
  );

  await ReminderStartupRecovery.runIfNeeded();

  await AttachmentLostDataRecovery.run();

  await FlowTaskWidgetService.refreshStandalone();

  runApp(const ProviderScope(child: FlowTaskApp()));

  HomeWidget.widgetClicked.listen(_handleWidgetLaunch);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (initialWidgetUri != null) {
      _handleWidgetLaunch(initialWidgetUri);
      return;
    }

    if (initialTaskId != null && initialTaskId != '__test__') {
      router.go('/task/$initialTaskId');
    }
  });
}

void _handleWidgetLaunch(Uri? uri) {
  router.go(FlowTaskWidgetLink.routeForUri(uri));
}
