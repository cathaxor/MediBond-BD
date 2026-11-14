import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/document_vault_storage.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/prescription.dart';
import 'package:medibond_bd/data/repositories/prescription_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late DocumentVaultStorage vaultStorage;
  late ProfileRepository profileRepo;
  late PrescriptionRepository prescriptionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    encryptionService = SecureEncryptionService();
    vaultStorage = DocumentVaultStorage(
      encryptionService: encryptionService,
      baseDirectory: Directory.systemTemp,
    );
    profileRepo = DriftProfileRepository(db, encryptionService);
    prescriptionRepo = DriftPrescriptionRepository(
      db,
      encryptionService,
      vaultStorage: vaultStorage,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 7 Secure Offline Prescription Vault Tests', () {
    test(
      'DocumentVaultStorage encrypts file bytes at rest and decrypts on demand',
      () async {
        final sampleBytes = Uint8List.fromList([
          77,
          101,
          100,
          105,
          66,
          111,
          110,
          100,
        ]);
        final fileId = const Uuid().v4();

        final encPath = await vaultStorage.saveEncryptedDocument(
          fileId: fileId,
          rawBytes: sampleBytes,
        );

        expect(encPath.endsWith('.enc'), isTrue);

        final decrypted = await vaultStorage.readDecryptedDocument(encPath);
        expect(decrypted, isNotNull);
        expect(decrypted, sampleBytes);

        await vaultStorage.deleteDocument(encPath);
      },
    );

    test('PrescriptionRepository saves, renames, and deletes prescriptions with encrypted storage', () async {
      final profileId = const Uuid().v4();
      await profileRepo.saveProfile(
        FamilyMember(
          id: profileId,
          name: 'Tanvir',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 32,
          bloodGroup: 'O+',
          avatarInitials: 'TA',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        ),
      );

      final rxId = const Uuid().v4();
      final rx = Prescription(
        id: rxId,
        title: 'Cardiology Visit',
        doctorName: 'Dr. Jalil',
        hospitalName: 'National Heart Foundation',
        date: DateTime.now(),
        familyMemberId: profileId,
        notes: 'Strict Low Salt Diet',
        tags: const ['Cardiology', 'ECG'],
      );

      final docBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      await prescriptionRepo.savePrescription(rx, rawDocumentBytes: docBytes);

      var list = await prescriptionRepo.getAllPrescriptions();
      expect(list.length, 1);
      expect(list.first.title, 'Cardiology Visit');
      expect(list.first.notes, 'Strict Low Salt Diet');
      expect(list.first.imageUrl, isNotNull);

      await prescriptionRepo.updatePrescriptionTitle(
        rxId,
        'Updated Cardiology Visit',
      );
      list = await prescriptionRepo.getAllPrescriptions();
      expect(list.first.title, 'Updated Cardiology Visit');

      await prescriptionRepo.deletePrescription(rxId);
      list = await prescriptionRepo.getAllPrescriptions();
      expect(list.isEmpty, isTrue);
    });
  });
}
