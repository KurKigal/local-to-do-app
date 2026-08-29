import 'dart:convert';

class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.createdAtUtc,
    required this.databaseSchemaVersion,
    required this.taskCount,
    required this.attachmentCount,
  });

  static const currentFormatVersion = 1;

  final int formatVersion;
  final DateTime createdAtUtc;
  final int databaseSchemaVersion;
  final int taskCount;
  final int attachmentCount;

  String encode() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'FlowTask',
      'formatVersion': formatVersion,
      'createdAtUtc':
          createdAtUtc.toUtc().toIso8601String(),
      'databaseSchemaVersion':
          databaseSchemaVersion,
      'taskCount': taskCount,
      'attachmentCount': attachmentCount,
    });
  }

  static BackupManifest decode(
    String source,
  ) {
    final value = jsonDecode(source);

    if (value is! Map<String, dynamic> ||
        value['app'] != 'FlowTask') {
      throw const FormatException(
        'This is not a FlowTask backup.',
      );
    }

    final formatVersion =
        value['formatVersion'];
    final createdAt =
        value['createdAtUtc'];
    final schemaVersion =
        value['databaseSchemaVersion'];

    if (formatVersion is! int ||
        createdAt is! String ||
        schemaVersion is! int) {
      throw const FormatException(
        'Backup manifest is incomplete.',
      );
    }

    return BackupManifest(
      formatVersion: formatVersion,
      createdAtUtc: DateTime.parse(createdAt),
      databaseSchemaVersion:
          schemaVersion,
      taskCount:
          value['taskCount'] is int
              ? value['taskCount'] as int
              : 0,
      attachmentCount:
          value['attachmentCount'] is int
              ? value['attachmentCount']
                  as int
              : 0,
    );
  }
}
