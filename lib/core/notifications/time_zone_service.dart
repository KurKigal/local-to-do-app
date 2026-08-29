import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class TimeZoneService {
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    try {
      final deviceTimeZone =
          await FlutterTimezone.getLocalTimezone();

      final location = tz.getLocation(
        deviceTimeZone.identifier,
      );

      tz.setLocalLocation(location);
    } catch (_) {
      // timezone package starts with UTC as local.
      // This is only a defensive fallback.
      tz.setLocalLocation(tz.UTC);
    }
  }

  static String get currentName {
    return tz.local.name;
  }
}