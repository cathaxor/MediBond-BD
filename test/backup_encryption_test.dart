import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/backup_service.dart';
import 'package:medibond_bd/core/security/document_vault_storage.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/medicine.dart';
import 'package:medibond_bd/data/repositories/dose_event_repository.dart';
import 'package:medibond_bd/data/repositories/medicine_repository.dart';
import 'package:medibond_bd/data/repositories/prescription_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late ProfileRepository profileRepo;
  late MedicineRepository medicineRepo;
  late DoseEventRepository doseEventRepo;
  late PrescriptionRepository prescriptionRepo;
  late BackupService backupService;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (methodCall) async => true,
        );

    db = AppDatabase(NativeDatabase.memory());
    encryptionService = SecureEncryptionService();
    profileRepo = DriftProfileRepository(db, encryptionService);
    medicineRepo = DriftMedicineRepository(db, encryptionService);
    doseEventRepo = DriftDoseEventRepository(db);
    prescriptionRepo = DriftPrescriptionRepository(db, encryptionService);
    backupService = BackupService(
      profileRepo: profileRepo,
      medicineRepo: medicineRepo,
      doseEventRepo: doseEventRepo,
      prescriptionRepo: prescriptionRepo,
      vaultStorage: DocumentVaultStorage(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Encrypted Backup & Restore Tests (.medibond)', () {
    test(
      'Successful encrypted export and decryption with correct password',
      () async {
        const userId = 'user_test_123';
        const password = 'StrongBackupPassword123!';

        // Create primary profile
        const primary = FamilyMember(
          id: 'primary_self',
          name: 'Tanvir Ahmed',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 32,
          bloodGroup: 'O+',
          avatarInitials: 'TA',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        );
        await profileRepo.saveProfile(primary);

        // Create medicine
        final med = Medicine(
          id: 'med_test_1',
          name: 'Napa Extra',
          form: MedicineForm.tablet,
          dosage: '1 Tablet',
          instructions: MealInstruction.afterFood,
          timesPerDay: 1,
          scheduledTimes: [],
          familyMemberId: 'primary_self',
          stockCount: 10,
          reorderThreshold: 3,
          startDate: DateTime.now(),
        );
        await medicineRepo.saveMedicine(med);

        // Export
        final backupBytes = await backupService.createEncryptedBackup(
          password: password,
          userId: userId,
        );

        expect(backupBytes.isNotEmpty, isTrue);

        // Preview & Decrypt
        final preview = await backupService.previewEncryptedBackup(
          backupBytes: backupBytes,
          password: password,
          activeUserId: userId,
        );

        expect(preview.profilesCount, 1);
        expect(preview.medicinesCount, 1);
        expect(preview.userId, userId);
      },
    );

    test('Rejection on wrong backup password', () async {
      const userId = 'user_test_123';
      const correctPassword = 'CorrectPassword123!';
      const wrongPassword = 'WrongPassword456!';

      final backupBytes = await backupService.createEncryptedBackup(
        password: correctPassword,
        userId: userId,
      );

      expect(
        () => backupService.previewEncryptedBackup(
          backupBytes: backupBytes,
          password: wrongPassword,
          activeUserId: userId,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('Rejection on cross-account restore', () async {
      const ownerUserId = 'owner_user_1';
      const wrongUserId = 'different_user_2';
      const password = 'Password123!';

      final backupBytes = await backupService.createEncryptedBackup(
        password: password,
        userId: ownerUserId,
      );

      expect(
        () => backupService.previewEncryptedBackup(
          backupBytes: backupBytes,
          password: password,
          activeUserId: wrongUserId,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Restore in Replace mode restores records cleanly', () async {
      const userId = 'user_test_123';
      const password = 'Password123!';

      const primary = FamilyMember(
        id: 'primary_self',
        name: 'Tanvir Ahmed',
        relationship: 'Self',
        relationshipBn: 'আমি',
        age: 32,
        bloodGroup: 'B+',
        avatarInitials: 'TA',
        avatarColorValue: 0xFF087F79,
        emergencyContact: '+880 1700 000000',
      );
      await profileRepo.saveProfile(primary);

      final backupBytes = await backupService.createEncryptedBackup(
        password: password,
        userId: userId,
      );

      // Clear local profiles
      await profileRepo.deleteProfile('primary_self');
      expect((await profileRepo.getAllProfiles()).isEmpty, isTrue);

      // Restore
      final preview = await backupService.previewEncryptedBackup(
        backupBytes: backupBytes,
        password: password,
        activeUserId: userId,
      );

      await backupService.restoreBackupData(
        preview: preview,
        mode: RestoreMode.replace,
      );

      final restoredProfiles = await profileRepo.getAllProfiles();
      expect(restoredProfiles.length, 1);
      expect(restoredProfiles.first.name, 'Tanvir Ahmed');
      expect(restoredProfiles.first.bloodGroup, 'B+');
    });
  });
}
