import 'package:drift/drift.dart';

import '../database/app_database.dart';

abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Future<void> saveSetting(String key, String value);
}

class DriftSettingsRepository implements SettingsRepository {
  final AppDatabase _db;

  DriftSettingsRepository(this._db);

  @override
  Future<String?> getSetting(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            key: Value(key),
            value: Value(value),
            updatedAt: Value(now),
          ),
        );
  }
}
