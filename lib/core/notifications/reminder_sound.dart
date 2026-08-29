import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSound {
  const ReminderSound({
    required this.key,
    required this.label,
    this.resource,
    this.contentUri,
    this.isSilent = false,
  });

  final String key;
  final String label;
  final String? resource;
  final String? contentUri;
  final bool isSilent;

  bool get isImported => contentUri != null;

  String get channelId {
    if (!isImported) {
      return 'task_reminders_$key';
    }

    return 'task_reminders_custom_${_stableHash(contentUri!)}';
  }

  AndroidNotificationSound? get androidSound {
    if (contentUri != null) {
      return UriAndroidNotificationSound(contentUri!);
    }
    if (resource != null) {
      return RawResourceAndroidNotificationSound(resource!);
    }
    return null;
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

abstract final class ReminderSounds {
  static const systemDefault = ReminderSound(
    key: 'default',
    label: 'System default',
  );

  static const silent = ReminderSound(
    key: 'silent',
    label: 'Silent / no sound',
    isSilent: true,
  );

  /// Optional APK-bundled sounds can still be registered here.
  static const bundled = <ReminderSound>[];

  static const fixed = <ReminderSound>[systemDefault, silent, ...bundled];

  static ReminderSound fixedFromKey(String? key) {
    return fixed.firstWhere(
      (sound) => sound.key == key,
      orElse: () => systemDefault,
    );
  }
}

class ReminderSoundPreference {
  static const _key = 'reminder_sound';
  static const _uriKey = 'reminder_sound_content_uri';
  static const _nameKey = 'reminder_sound_display_name';

  static Future<ReminderSound> load() async {
    final preferences = await SharedPreferences.getInstance();
    final key = preferences.getString(_key);

    if (key == 'custom') {
      final uri = preferences.getString(_uriKey);
      final name = preferences.getString(_nameKey);
      if (uri != null && uri.isNotEmpty && name != null && name.isNotEmpty) {
        return ReminderSound(key: 'custom', label: name, contentUri: uri);
      }
    }

    return ReminderSounds.fixedFromKey(key);
  }

  static Future<void> save(ReminderSound sound) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, sound.key);

    if (sound.isImported) {
      await preferences.setString(_uriKey, sound.contentUri!);
      await preferences.setString(_nameKey, sound.label);
    } else {
      await preferences.remove(_uriKey);
      await preferences.remove(_nameKey);
    }
  }
}

class ReminderSoundImporter {
  static const _channel = MethodChannel(
    'com.emirhankeser.flowtask/reminder_sound',
  );

  static Future<ReminderSound?> chooseAndImport() async {
    final result = await _channel.invokeMapMethod<String, String>(
      'chooseAndImport',
    );
    final uri = result?['uri'];
    final name = result?['displayName'];
    if (uri == null || name == null) {
      return null;
    }
    return ReminderSound(key: 'custom', label: name, contentUri: uri);
  }

  static Future<void> deleteImported(String uri) async {
    await _channel.invokeMethod<bool>('deleteImported', {'uri': uri});
  }
}

final reminderSoundProvider =
    AsyncNotifierProvider<ReminderSoundNotifier, ReminderSound>(
      ReminderSoundNotifier.new,
    );

class ReminderSoundNotifier extends AsyncNotifier<ReminderSound> {
  @override
  Future<ReminderSound> build() => ReminderSoundPreference.load();

  Future<void> setSound(ReminderSound sound) async {
    await ReminderSoundPreference.save(sound);
    state = AsyncData(sound);
  }
}
