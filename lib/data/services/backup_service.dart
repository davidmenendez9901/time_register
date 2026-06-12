import '../../core/database/database_helper.dart';
import '../../core/utils/backup_codec.dart';

/// Creates and restores full-app backups (settings + all work entries).
class BackupService {
  final DatabaseHelper databaseHelper;

  BackupService(this.databaseHelper);

  Future<String> createBackupJson() async {
    final settings = await databaseHelper.getSettings();
    final entries = await databaseHelper.getWorkEntries();
    return BackupCodec.encode(
      settings: settings,
      entries: entries,
      exportedAt: DateTime.now(),
    );
  }

  /// Replaces all current data with the backup contents.
  /// Throws [FormatException] when the JSON is not a valid backup.
  Future<void> restoreFromJson(String json) async {
    final data = BackupCodec.decode(json);
    await databaseHelper.restoreAll(
      settings: data.settings,
      entries: data.entries,
    );
  }
}
