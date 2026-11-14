import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/medicine.dart';
import 'package:medibond_bd/data/repositories/dose_event_repository.dart';
import 'package:medibond_bd/data/repositories/medicine_repository.dart';
import 'package:medibond_bd/data/repositories/prescription_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';
import 'package:medibond_bd/state/app_state_provider.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late ProfileRepository profileRepo;
  late MedicineRepository medicineRepo;
  late DoseEventRepository doseEventRepo;
  late PrescriptionRepository prescriptionRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    encryptionService = SecureEncryptionService();
    profileRepo = DriftProfileRepository(db, encryptionService);
    medicineRepo = DriftMedicineRepository(db, encryptionService);
    doseEventRepo = DriftDoseEventRepository(db);
    prescriptionRepo = DriftPrescriptionRepository(db, encryptionService);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4 Family Profile & Data Isolation Tests', () {
    test(
      'Profile CRUD with calculated birthYear and encrypted notes',
      () async {
        final id = const Uuid().v4();
        final member = FamilyMember(
          id: id,
          name: 'Grandfather',
          relationship: 'Grandparent',
          relationshipBn: 'দাদা',
          age: 75,
          birthYear: 1950,
          bloodGroup: 'AB+',
          avatarInitials: 'GF',
          avatarColorValue: 0xFF1E40AF,
          emergencyContact: '+880 1711 998877',
          medicalNotes: 'Encrypted Cardiac History',
        );

        await profileRepo.saveProfile(member);

        final fetched = await profileRepo.getProfileById(id);
        expect(fetched, isNotNull);
        expect(fetched!.name, 'Grandfather');
        expect(fetched.medicalNotes, 'Encrypted Cardiac History');
        expect(fetched.calculatedAge, greaterThan(70));

        await profileRepo.deleteProfile(id);
        final deleted = await profileRepo.getProfileById(id);
        expect(deleted, isNull);
      },
    );

    test('Data Isolation: Active profile filter strictly isolates medicines and logs', () async {
      final p1Id = const Uuid().v4();
      final p2Id = const Uuid().v4();

      final p1 = FamilyMember(
        id: p1Id,
        name: 'Member One',
        relationship: 'Self',
        relationshipBn: 'আমি',
        age: 30,
        bloodGroup: 'O+',
        avatarInitials: 'M1',
        avatarColorValue: 0xFF087F79,
        emergencyContact: '+880 1700 000001',
      );

      final p2 = FamilyMember(
        id: p2Id,
        name: 'Member Two',
        relationship: 'Spouse',
        relationshipBn: 'স্ত্রী',
        age: 28,
        bloodGroup: 'A+',
        avatarInitials: 'M2',
        avatarColorValue: 0xFF9D174D,
        emergencyContact: '+880 1700 000002',
      );

      await profileRepo.saveProfile(p1);
      await profileRepo.saveProfile(p2);

      final m1 = Medicine(
        id: const Uuid().v4(),
        name: 'Napa Extra',
        form: MedicineForm.tablet,
        dosage: '1 Tablet',
        instructions: MealInstruction.afterFood,
        timesPerDay: 1,
        scheduledTimes: const [TimeOfDay(hour: 8, minute: 0)],
        familyMemberId: p1Id,
        stockCount: 10,
        startDate: DateTime.now(),
      );

      final m2 = Medicine(
        id: const Uuid().v4(),
        name: 'Seclo 20mg',
        form: MedicineForm.capsule,
        dosage: '1 Capsule',
        instructions: MealInstruction.beforeFood,
        timesPerDay: 1,
        scheduledTimes: const [TimeOfDay(hour: 8, minute: 0)],
        familyMemberId: p2Id,
        stockCount: 5,
        startDate: DateTime.now(),
      );

      await medicineRepo.saveMedicine(m1);
      await medicineRepo.saveMedicine(m2);

      final p1Meds = await medicineRepo.getMedicinesByProfile(p1Id);
      final p2Meds = await medicineRepo.getMedicinesByProfile(p2Id);

      expect(p1Meds.length, 1);
      expect(p1Meds.first.name, 'Napa Extra');

      expect(p2Meds.length, 1);
      expect(p2Meds.first.name, 'Seclo 20mg');
    });

    test(
      'AppStateNotifier profile selection isolates filtered state',
      () async {
        final notifier = AppStateNotifier(
          profileRepo: profileRepo,
          medicineRepo: medicineRepo,
          doseEventRepo: doseEventRepo,
          prescriptionRepo: prescriptionRepo,
        );

        await notifier.initDatabase();

        expect(notifier.state.selectedFamilyMemberId, 'all');

        notifier.selectFamilyMember('m1');
        expect(notifier.state.selectedFamilyMemberId, 'm1');
      },
    );
  });
}
