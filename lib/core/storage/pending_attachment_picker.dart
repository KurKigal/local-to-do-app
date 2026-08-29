import 'package:shared_preferences/shared_preferences.dart';

abstract final class PendingAttachmentPicker {
  static const _taskIdKey =
      'pending_attachment_picker_task_id';

  static Future<void> begin(
    String taskId,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _taskIdKey,
      taskId,
    );
  }

  static Future<String?> taskId() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _taskIdKey,
    );
  }

  static Future<void> clear() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      _taskIdKey,
    );
  }
}
