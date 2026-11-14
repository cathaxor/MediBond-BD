import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/medication_log.dart';
import '../models/medicine.dart';

abstract class DoseEventRepository {
  Future<List<MedicationLog>> getAllLogs();
  Future<void> saveLog(MedicationLog log);
  Future<void> updateLogStatus(
    String logId,
    MedicationLogStatus status,
    DateTime? actionAt,
  );
  Future<void> deleteLog(String id);
  Future<void> seedInitialLogsIfEmpty(List<MedicationLog> defaultLogs);
}

class DriftDoseEventRepository implements DoseEventRepository {
  final AppDatabase _db;

  DriftDoseEventRepository(this._db);

  @override
  Future<List<MedicationLog>> getAllLogs() async {
    final rows = await _db.select(_db.doseEvents).get();
    final medicines = await _db.select(_db.medicines).get();

    final result = <MedicationLog>[];
    for (var r in rows) {
      final med = medicines.firstWhere(
        (m) => m.id == r.medicineId,
        orElse: () => medicines.isNotEmpty ? medicines.first : _dummyMedicine(),
      );

      final statusEnum = MedicationLogStatus.values.firstWhere(
        (s) => s.name == r.status,
        orElse: () => MedicationLogStatus.pending,
      );

      result.add(
        MedicationLog(
          id: r.id,
          medicineId: r.medicineId,
          medicineName: med.name,
          familyMemberId: r.profileId,
          dosage: med.dosage,
          form: MedicineForm.values.firstWhere(
            (f) => f.name == med.form,
            orElse: () => MedicineForm.tablet,
          ),
          instructions: MealInstruction.values.firstWhere(
            (i) => i.name == med.instructions,
            orElse: () => MealInstruction.afterFood,
          ),
          scheduledDateTime: r.scheduledAt.toLocal(),
          status: statusEnum,
          actionTime: r.actionAt?.toLocal(),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> saveLog(MedicationLog log) async {
    final now = DateTime.now().toUtc();
    final logId = log.id.isEmpty ? const Uuid().v4() : log.id;

    await _db
        .into(_db.doseEvents)
        .insertOnConflictUpdate(
          DoseEventsCompanion(
            id: Value(logId),
            medicineId: Value(log.medicineId),
            profileId: Value(log.familyMemberId),
            scheduledAt: Value(log.scheduledDateTime.toUtc()),
            status: Value(log.status.name),
            actionAt: Value(log.actionTime?.toUtc()),
            createdAt: Value(now),
          ),
        );
  }

  @override
  Future<void> updateLogStatus(
    String logId,
    MedicationLogStatus status,
    DateTime? actionAt,
  ) async {
    await (_db.update(_db.doseEvents)..where((e) => e.id.equals(logId))).write(
      DoseEventsCompanion(
        status: Value(status.name),
        actionAt: Value(actionAt?.toUtc()),
      ),
    );
  }

  @override
  Future<void> deleteLog(String id) async {
    await (_db.delete(_db.doseEvents)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<void> seedInitialLogsIfEmpty(List<MedicationLog> defaultLogs) async {
    final existing = await _db.select(_db.doseEvents).get();
    if (existing.isEmpty) {
      for (var l in defaultLogs) {
        await saveLog(l);
      }
    }
  }

  MedicineData _dummyMedicine() {
    return MedicineData(
      id: 'dummy',
      profileId: '',
      name: 'Medicine',
      strength: '',
      form: 'tablet',
      dosage: '1 Dose',
      instructions: 'afterFood',
      timesPerDay: 1,
      stockCount: 10,
      reorderThreshold: 3,
      colorHex: 0xFF087F79,
      isActive: true,
      isPaused: false,
      startDate: DateTime.now(),
      weekdays: '1,2,3,4,5,6,7',
      notes: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
