import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'reminder_sound.dart';

class NotificationPayload {
  const NotificationPayload({required this.taskId, this.reminderId});

  final String taskId;
  final String? reminderId;

  String encode() {
    return jsonEncode({'taskId': taskId, 'reminderId': reminderId});
  }

  static NotificationPayload? decode(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;

      final taskId = json['taskId'] as String?;

      if (taskId == null || taskId.isEmpty) {
        return null;
      }

      return NotificationPayload(
        taskId: taskId,
        reminderId: json['reminderId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String doneActionId = 'done';
  static const String snoozeActionId = 'snooze_10';

  Future<String?> initialize({
    required void Function(String taskId) onOpenTask,
    required DidReceiveBackgroundNotificationResponseCallback
    onBackgroundResponse,
  }) async {
    const androidSettings = AndroidInitializationSettings('ic_stat_flowtask');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _handleForegroundResponse(response, onOpenTask, onBackgroundResponse);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    for (final sound in ReminderSounds.fixed) {
      await android?.createNotificationChannel(_channelFor(sound));
    }

    final selectedSound = await ReminderSoundPreference.load();
    if (selectedSound.isImported) {
      await android?.createNotificationChannel(_channelFor(selectedSound));
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp != true) {
      return null;
    }

    final payload = NotificationPayload.decode(
      launchDetails?.notificationResponse?.payload,
    );

    return payload?.taskId;
  }

  Future<bool> requestNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<bool> canScheduleExactNotifications() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await android?.requestExactAlarmsPermission() ?? false;
  }

  Future<void> showTestNotification() async {
    final sound = await ReminderSoundPreference.load();

    await _plugin.show(
      id: 900001,
      title: 'FlowTask',
      body: 'Notifications are working.',
      notificationDetails: _notificationDetails(sound),
    );
  }

  Future<void> scheduleTestNotification({
    Duration delay = const Duration(seconds: 30),
  }) async {
    final scheduleAt = DateTime.now().add(delay);

    await schedule(
      notificationId: 900002,
      title: 'FlowTask test',
      body: 'Scheduled reminders are working.',
      scheduledAt: scheduleAt,
      payload: const NotificationPayload(taskId: '__test__'),
    );
  }

  Future<void> schedule({
    required int notificationId,
    required String title,
    required DateTime scheduledAt,
    required NotificationPayload payload,
    String? body,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) {
      throw ArgumentError('Notification must be scheduled in the future.');
    }

    final exact = await canScheduleExactNotifications();

    final scheduleMode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final zonedDate = tz.TZDateTime.from(scheduledAt, tz.local);

    final sound = await ReminderSoundPreference.load();

    await _plugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body ?? 'Task reminder',
      scheduledDate: zonedDate,
      notificationDetails: _notificationDetails(sound),
      androidScheduleMode: scheduleMode,
      payload: payload.encode(),
    );
  }

  Future<void> cancel(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  Future<void> deleteReminderChannel(String channelId) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.deleteNotificationChannel(channelId: channelId);
  }

  Future<void> ensureReminderChannel(ReminderSound sound) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channelFor(sound));
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _plugin.pendingNotificationRequests();
  }

  void _handleForegroundResponse(
    NotificationResponse response,
    void Function(String taskId) onOpenTask,
    DidReceiveBackgroundNotificationResponseCallback onAction,
  ) {
    final payload = NotificationPayload.decode(response.payload);

    if (payload == null) {
      return;
    }

    if (payload.taskId == '__test__') {
      return;
    }

    switch (response.actionId) {
      case doneActionId:
      case snoozeActionId:
        onAction(response);
        break;

      default:
        onOpenTask(payload.taskId);
    }
  }

  static AndroidNotificationChannel _channelFor(ReminderSound sound) {
    return AndroidNotificationChannel(
      sound.channelId,
      'Task reminders (${sound.label})',
      description: 'Notifications for scheduled task reminders',
      importance: Importance.high,
      playSound: !sound.isSilent,
      sound: sound.androidSound,
    );
  }

  static NotificationDetails _notificationDetails(ReminderSound sound) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        sound.channelId,
        'Task reminders (${sound.label})',
        channelDescription: 'Notifications for scheduled task reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_flowtask',
        playSound: !sound.isSilent,
        sound: sound.androidSound,
        actions: const [
          AndroidNotificationAction(
            doneActionId,
            'Done',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            snoozeActionId,
            'Snooze 10m',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      ),
    );
  }
}
