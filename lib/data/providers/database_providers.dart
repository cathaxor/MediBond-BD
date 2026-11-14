import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/secure_encryption_service.dart';
import '../database/app_database.dart';
import '../repositories/dose_event_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/prescription_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/settings_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final encryptionServiceProvider = Provider<SecureEncryptionService>((ref) {
  return SecureEncryptionService();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return DriftProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
  );
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  return DriftMedicineRepository(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
  );
});

final doseEventRepositoryProvider = Provider<DoseEventRepository>((ref) {
  return DriftDoseEventRepository(ref.watch(databaseProvider));
});

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return DriftPrescriptionRepository(
    ref.watch(databaseProvider),
    ref.watch(encryptionServiceProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(ref.watch(databaseProvider));
});
