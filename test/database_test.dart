import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/medication_log.dart';
import 'package:medibond_bd/data/models/medicine.dart';
import 'package:medibond_bd/data/models/prescription.dart';
import 'package:medibond_bd/data/repositories/dose_event_repository.dart';
import 'package:medibond_bd/data/repositories/medicine_repository.dart';
import 'package:medibond_bd/data/repositories/prescription_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late ProfileRepository profileRepo;
  late MedicineRepository medicineRepo;
  late DoseEventRepository doseEventRepo;
  late PrescriptionRepository prescriptionRepo;

  setUp(() {
    // In-memory database for testing
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

  group('Drift SQLite Database & Repository Unit Tests', () {
    test('Profiles CRUD and Notes Encryption', () async {
      final id = const Uuid().v4();
      final member = FamilyMember(
        id: id,
        name: 'Test Member',
        relationship: 'Self',
        relationshipBn: 'আমি',
        age: 30,
        bloodGroup: 'B+',
        avatarInitials: 'TM',
        avatarColorValue: 0xFF087F79,
        emergencyContact: '+880 1700 000000',
        medicalNotes: 'Sensitive Medical Note 123',
      );

      await profileRepo.saveProfile(member);

      final fetched = await profileRepo.getProfileById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test Member');
      expect(fetched.medicalNotes, 'Sensitive Medical Note 123');

      // Verify encrypted state in raw database
      final rawRow = await (db.select(
        db.profiles,
      )..where((p) => p.id.equals(id))).getSingle();
      expect(rawRow.medicalNotes.startsWith('ENC:'), isTrue);

      // Delete
      await profileRepo.deleteProfile(id);
      final deleted = await profileRepo.getProfileById(id);
      expect(deleted, isNull);
    });

    test('Medicines CRUD & Foreign Key Relationships', () async {
      final profileId = const Uuid().v4();
      final member = FamilyMember(
        id: profileId,
        name: 'Parent',
        relationship: 'Father',
        relationshipBn: 'বাবা',
        age: 60,
        bloodGroup: 'A+',
        avatarInitials: 'PA',
        avatarColorValue: 0xFF1E40AF,
        emergencyContact: '+880 1800 000000',
      );
      await profileRepo.saveProfile(member);

      final medId = const Uuid().v4();
      final med = Medicine(
        id: medId,
        name: 'Paracetamol 500mg',
        form: MedicineForm.tablet,
        dosage: '1 Tablet',
        instructions: MealInstruction.afterFood,
        timesPerDay: 2,
        scheduledTimes: const [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
        familyMemberId: profileId,
        stockCount: 15,
        startDate: DateTime.now(),
      );

      await medicineRepo.saveMedicine(med);

      final meds = await medicineRepo.getMedicinesByProfile(profileId);
      expect(meds.length, 1);
      expect(meds.first.name, 'Paracetamol 500mg');
      expect(meds.first.scheduledTimes.length, 2);
    });

    test('Dose Events status tracking and UTC handling', () async {
      final profileId = const Uuid().v4();
      await profileRepo.saveProfile(
        FamilyMember(
          id: profileId,
          name: 'User',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 25,
          bloodGroup: 'O+',
          avatarInitials: 'US',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        ),
      );

      final medId = const Uuid().v4();
      await medicineRepo.saveMedicine(
        Medicine(
          id: medId,
          name: 'Seclo 20mg',
          form: MedicineForm.capsule,
          dosage: '1 Capsule',
          instructions: MealInstruction.beforeFood,
          timesPerDay: 1,
          scheduledTimes: const [TimeOfDay(hour: 8, minute: 0)],
          familyMemberId: profileId,
          stockCount: 10,
          startDate: DateTime.now(),
        ),
      );

      final logId = const Uuid().v4();
      final scheduledDT = DateTime.now();
      final log = MedicationLog(
        id: logId,
        medicineId: medId,
        medicineName: 'Seclo 20mg',
        familyMemberId: profileId,
        dosage: '1 Capsule',
        form: MedicineForm.capsule,
        instructions: MealInstruction.beforeFood,
        scheduledDateTime: scheduledDT,
        status: MedicationLogStatus.pending,
      );

      await doseEventRepo.saveLog(log);

      final logsBefore = await doseEventRepo.getAllLogs();
      expect(logsBefore.length, 1);
      expect(logsBefore.first.status, MedicationLogStatus.pending);

      // Update to taken
      final takeTime = DateTime.now();
      await doseEventRepo.updateLogStatus(
        logId,
        MedicationLogStatus.taken,
        takeTime,
      );

      final logsAfter = await doseEventRepo.getAllLogs();
      expect(logsAfter.first.status, MedicationLogStatus.taken);
      expect(logsAfter.first.actionTime, isNotNull);
    });

    test('Prescriptions CRUD & encrypted notes', () async {
      final profileId = const Uuid().v4();
      await profileRepo.saveProfile(
        FamilyMember(
          id: profileId,
          name: 'Member',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 28,
          bloodGroup: 'AB+',
          avatarInitials: 'ME',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        ),
      );

      final rxId = const Uuid().v4();
      final rx = Prescription(
        id: rxId,
        title: 'Routine Health Check',
        doctorName: 'Dr. Rahim',
        hospitalName: 'Square Hospital',
        date: DateTime.now(),
        familyMemberId: profileId,
        notes: 'Confidential Diagnosis Details',
        tags: const ['General', 'Routine'],
      );

      await prescriptionRepo.savePrescription(rx);

      final rxList = await prescriptionRepo.getAllPrescriptions();
      expect(rxList.length, 1);
      expect(rxList.first.title, 'Routine Health Check');
      expect(rxList.first.notes, 'Confidential Diagnosis Details');
    });

    test('SecureEncryptionService encrypt/decrypt helper', () async {
      const secret = 'Top Secret Medical Record Data';
      final encrypted = await encryptionService.encrypt(secret);
      expect(encrypted.startsWith('ENC:'), isTrue);

      final decrypted = await encryptionService.decrypt(encrypted);
      expect(decrypted, secret);
    });
  });
}
