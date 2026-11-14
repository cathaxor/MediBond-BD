import 'medicine.dart';

enum MedicationLogStatus { pending, taken, missed, skipped }

class MedicationLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final String familyMemberId;
  final String dosage;
  final MedicineForm form;
  final MealInstruction instructions;
  final DateTime scheduledDateTime;
  final MedicationLogStatus status;
  final DateTime? actionTime;

  const MedicationLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.familyMemberId,
    required this.dosage,
    required this.form,
    required this.instructions,
    required this.scheduledDateTime,
    this.status = MedicationLogStatus.pending,
    this.actionTime,
  });

  MedicationLog copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? familyMemberId,
    String? dosage,
    MedicineForm? form,
    MealInstruction? instructions,
    DateTime? scheduledDateTime,
    MedicationLogStatus? status,
    DateTime? actionTime,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      instructions: instructions ?? this.instructions,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      actionTime: actionTime ?? this.actionTime,
    );
  }
}
