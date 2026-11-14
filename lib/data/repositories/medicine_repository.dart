import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/security/secure_encryption_service.dart';
import '../database/app_database.dart';
import '../models/medicine.dart';

abstract class MedicineRepository {
  Future<List<Medicine>> getAllMedicines();
  Future<List<Medicine>> getMedicinesByProfile(String profileId);
  Future<Medicine?> getMedicineById(String id);
  Future<void> saveMedicine(Medicine medicine);
  Future<void> togglePauseMedicine(String id, bool isPaused);
  Future<void> toggleArchiveMedicine(String id, bool isActive);
  Future<void> deleteMedicine(String id);
  Future<void> seedInitialMedicinesIfEmpty(List<Medicine> defaultMeds);
}

class DriftMedicineRepository implements MedicineRepository {
  final AppDatabase _db;
  final SecureEncryptionService _encryption;

  DriftMedicineRepository(this._db, this._encryption);

  @override
  Future<List<Medicine>> getAllMedicines() async {
    final rows = await _db.select(_db.medicines).get();
    final list = <Medicine>[];
    for (var r in rows) {
      final decryptedNotes = await _encryption.decrypt(r.notes);
      final schedules = await (_db.select(
        _db.doseSchedules,
      )..where((s) => s.medicineId.equals(r.id))).get();

      final times = schedules
          .map((s) => TimeOfDay(hour: s.timeHour, minute: s.timeMinute))
          .toList();

      final parsedWeekdays = r.weekdays.isNotEmpty
          ? r.weekdays.split(',').map((e) => int.tryParse(e) ?? 1).toList()
          : const [1, 2, 3, 4, 5, 6, 7];

      list.add(
        Medicine(
          id: r.id,
          name: r.name,
          strength: r.strength,
          form: MedicineForm.values.firstWhere(
            (f) => f.name == r.form,
            orElse: () => MedicineForm.tablet,
          ),
          dosage: r.dosage,
          instructions: MealInstruction.values.firstWhere(
            (i) => i.name == r.instructions,
            orElse: () => MealInstruction.afterFood,
          ),
          timesPerDay: r.timesPerDay,
          scheduledTimes: times,
          familyMemberId: r.profileId,
          stockCount: r.stockCount,
          reorderThreshold: r.reorderThreshold,
          isActive: r.isActive,
          isPaused: r.isPaused,
          colorHex: r.colorHex,
          startDate: r.startDate.toLocal(),
          endDate: r.endDate?.toLocal(),
          weekdays: parsedWeekdays,
          notes: decryptedNotes,
        ),
      );
    }
    return list;
  }

  @override
  Future<List<Medicine>> getMedicinesByProfile(String profileId) async {
    final all = await getAllMedicines();
    return all.where((m) => m.familyMemberId == profileId).toList();
  }

  @override
  Future<Medicine?> getMedicineById(String id) async {
    final all = await getAllMedicines();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveMedicine(Medicine medicine) async {
    final encryptedNotes = await _encryption.encrypt(medicine.notes);
    final now = DateTime.now().toUtc();
    final medId = medicine.id.isEmpty ? const Uuid().v4() : medicine.id;

    final weekdayString = medicine.weekdays.join(',');

    await _db
        .into(_db.medicines)
        .insertOnConflictUpdate(
          MedicinesCompanion(
            id: Value(medId),
            profileId: Value(medicine.familyMemberId),
            name: Value(medicine.name),
            strength: Value(medicine.strength),
            form: Value(medicine.form.name),
            dosage: Value(medicine.dosage),
            instructions: Value(medicine.instructions.name),
            timesPerDay: Value(medicine.timesPerDay),
            stockCount: Value(medicine.stockCount),
            reorderThreshold: Value(medicine.reorderThreshold),
            colorHex: Value(medicine.colorHex),
            isActive: Value(medicine.isActive),
            isPaused: Value(medicine.isPaused),
            startDate: Value(medicine.startDate.toUtc()),
            endDate: Value(medicine.endDate?.toUtc()),
            weekdays: Value(weekdayString),
            notes: Value(encryptedNotes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Save schedules
    await (_db.delete(
      _db.doseSchedules,
    )..where((s) => s.medicineId.equals(medId))).go();
    for (var time in medicine.scheduledTimes) {
      await _db
          .into(_db.doseSchedules)
          .insert(
            DoseSchedulesCompanion(
              id: Value(const Uuid().v4()),
              medicineId: Value(medId),
              timeHour: Value(time.hour),
              timeMinute: Value(time.minute),
              createdAt: Value(now),
            ),
          );
    }
  }

  @override
  Future<void> togglePauseMedicine(String id, bool isPaused) async {
    await (_db.update(_db.medicines)..where((m) => m.id.equals(id))).write(
      MedicinesCompanion(
        isPaused: Value(isPaused),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> toggleArchiveMedicine(String id, bool isActive) async {
    await (_db.update(_db.medicines)..where((m) => m.id.equals(id))).write(
      MedicinesCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> deleteMedicine(String id) async {
    await (_db.delete(_db.medicines)..where((m) => m.id.equals(id))).go();
  }

  @override
  Future<void> seedInitialMedicinesIfEmpty(List<Medicine> defaultMeds) async {
    final existing = await _db.select(_db.medicines).get();
    if (existing.isEmpty) {
      for (var m in defaultMeds) {
        await saveMedicine(m);
      }
    }
  }
}
