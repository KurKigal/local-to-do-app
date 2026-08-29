import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/theme_provider.dart';
import '../../../shared/feedback/flowtask_haptics.dart';
import '../../../core/notifications/notification_provider.dart';
import '../../../core/notifications/reminder_sound.dart';
import '../../../core/notifications/time_zone_service.dart';
import '../../tasks/providers/task_providers.dart';
import 'widgets/data_storage_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final current = themeMode.valueOrNull ?? ThemeMode.system;
    final reminderSound =
        ref.watch(reminderSoundProvider).valueOrNull ??
        ReminderSounds.systemDefault;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _SectionTitle(
            title: 'Appearance',
            subtitle: 'Dark mode uses an AMOLED-first true-black background.',
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {current},
            onSelectionChanged: (selection) async {
              await FlowTaskHaptics.selection();

              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selection.first);
            },
          ),

          const SizedBox(height: 32),

          const _SectionTitle(
            title: 'Organization',
            subtitle: 'Manage reusable task metadata and deleted tasks.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: const Text('Tags'),
                  subtitle: const Text('Rename, recolor or delete tags'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await FlowTaskHaptics.selection();

                    if (!context.mounted) {
                      return;
                    }

                    context.push('/tags');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Trash'),
                  subtitle: const Text('Restore or permanently delete tasks'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await FlowTaskHaptics.selection();

                    if (!context.mounted) {
                      return;
                    }

                    context.push('/trash');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const _SectionTitle(
            title: 'Notifications',
            subtitle: 'Local Android reminders only. No cloud service is used.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Allow notifications'),
                  subtitle: const Text('Required for task reminders'),
                  onTap: () async {
                    await FlowTaskHaptics.selection();

                    final granted = await ref
                        .read(notificationServiceProvider)
                        .requestNotificationPermission();

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? 'Notification permission granted'
                              : 'Notification permission not granted',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.music_note_rounded),
                  title: const Text('Reminder sound'),
                  subtitle: Text(reminderSound.label),
                  trailing: IconButton(
                    tooltip: 'Test reminder sound',
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .showTestNotification();
                    },
                  ),
                  onTap: () =>
                      _chooseReminderSound(context, ref, reminderSound),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.alarm_rounded),
                  title: const Text('Precise reminders'),
                  subtitle: const Text(
                    'Use Android exact alarms when permission is available',
                  ),
                  onTap: () async {
                    await FlowTaskHaptics.selection();

                    final service = ref.read(notificationServiceProvider);

                    var enabled = await service.canScheduleExactNotifications();

                    if (!enabled) {
                      await service.requestExactAlarmPermission();

                      enabled = await service.canScheduleExactNotifications();
                    }

                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          enabled
                              ? 'Precise reminders enabled'
                              : 'FlowTask will use inexact reminders',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public_rounded),
                  title: const Text('Timezone'),
                  subtitle: Text(TimeZoneService.currentName),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const DataStorageSection(),
        ],
      ),
    );
  }

  Future<void> _chooseReminderSound(
    BuildContext context,
    WidgetRef ref,
    ReminderSound current,
  ) async {
    await FlowTaskHaptics.selection();

    if (!context.mounted) {
      return;
    }

    const chooseFile = ReminderSound(
      key: 'choose_file',
      label: 'Choose audio file...',
    );

    var selected = await showDialog<ReminderSound>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Reminder sound'),
        children: [
          for (final sound in ReminderSounds.fixed)
            _SoundOption(
              sound: sound,
              selected: sound.key == current.key,
              onPressed: () => Navigator.of(dialogContext).pop(sound),
            ),
          if (current.isImported)
            _SoundOption(
              sound: current,
              selected: true,
              onPressed: () => Navigator.of(dialogContext).pop(current),
            ),
          const Divider(),
          _SoundOption(
            sound: chooseFile,
            selected: false,
            icon: Icons.audio_file_rounded,
            onPressed: () => Navigator.of(dialogContext).pop(chooseFile),
          ),
        ],
      ),
    );

    if (selected == null) {
      return;
    }

    if (selected.key == chooseFile.key) {
      try {
        selected = await ReminderSoundImporter.chooseAndImport();
      } on PlatformException catch (error) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not import audio.')),
        );
        return;
      }
    }

    if (selected == null || selected.channelId == current.channelId) {
      return;
    }

    final notifier = ref.read(reminderSoundProvider.notifier);
    final reminders = ref.read(reminderRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);

    try {
      await notifier.setSound(selected);
      await notifications.ensureReminderChannel(selected);
      await reminders.rescheduleAllFuture();
    } catch (_) {
      var restored = false;
      try {
        await notifier.setSound(current);
        await notifications.ensureReminderChannel(current);
        await reminders.rescheduleAllFuture();
        restored = true;
      } catch (_) {
        // Keep the imported item if rollback fails so scheduled notifications
        // never point at a deleted sound URI.
      }

      if (restored &&
          selected.isImported &&
          selected.contentUri != current.contentUri) {
        await notifications.deleteReminderChannel(selected.channelId);
        await ReminderSoundImporter.deleteImported(selected.contentUri!);
      }

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change the reminder sound.')),
      );
      return;
    }

    if (current.isImported && current.contentUri != selected.contentUri) {
      await notifications.deleteReminderChannel(current.channelId);
      await ReminderSoundImporter.deleteImported(current.contentUri!);
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder sound changed to ${selected.label}')),
    );
  }
}

class _SoundOption extends StatelessWidget {
  const _SoundOption({
    required this.sound,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final ReminderSound sound;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(
            icon ??
                (selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(sound.label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
