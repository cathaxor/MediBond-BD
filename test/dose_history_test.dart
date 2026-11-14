import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/util/csv_exporter.dart';
import 'package:medibond_bd/core/util/dose_statistics.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/medication_log.dart';
import 'package:medibond_bd/data/models/medicine.dart';

void main() {
  group('Phase 6 Dose History & Statistics Unit Tests', () {
    test(
      'DoseStatistics calculates adherence rate and overdue doses correctly',
      () {
        final now = DateTime(2025, 1, 15, 12, 0);

        final logs = [
          MedicationLog(
            id: 'log1',
            medicineId: 'm1',
            medicineName: 'Napa Extra',
            familyMemberId: 'p1',
            dosage: '1 Tablet',
            form: MedicineForm.tablet,
            instructions: MealInstruction.afterFood,
            scheduledDateTime: DateTime(2025, 1, 15, 8, 0),
            status: MedicationLogStatus.taken,
            actionTime: DateTime(2025, 1, 15, 8, 5),
          ),
          MedicationLog(
            id: 'log2',
            medicineId: 'm1',
            medicineName: 'Napa Extra',
            familyMemberId: 'p1',
            dosage: '1 Tablet',
            form: MedicineForm.tablet,
            instructions: MealInstruction.afterFood,
            scheduledDateTime: DateTime(
              2025,
              1,
              15,
              10,
              0,
            ), // Overdue pending dose
            status: MedicationLogStatus.pending,
          ),
          MedicationLog(
            id: 'log3',
            medicineId: 'm2',
            medicineName: 'Seclo 20mg',
            familyMemberId: 'p1',
            dosage: '1 Capsule',
            form: MedicineForm.capsule,
            instructions: MealInstruction.beforeFood,
            scheduledDateTime: DateTime(2025, 1, 15, 14, 0), // Future pending
            status: MedicationLogStatus.pending,
          ),
        ];

        final stats = DoseStatistics.calculate(logs, now: now);

        expect(stats.totalScheduled, 3);
        expect(stats.takenCount, 1);
        expect(stats.pendingCount, 2);
        expect(stats.overdueCount, 1); // 10:00 AM is 2 hours before 12:00 PM
        expect(
          stats.adherencePercentage,
          100,
        ); // 1 taken out of 1 eligible (excluding pending future)
      },
    );

    test(
      'CsvExporter generates valid CSV formatted output without uploading data',
      () {
        final member = const FamilyMember(
          id: 'p1',
          name: 'Tanvir Ahmed',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 32,
          bloodGroup: 'O+',
          avatarInitials: 'TA',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        );

        final log = MedicationLog(
          id: 'log_csv_1',
          medicineId: 'm1',
          medicineName: 'Concor 5mg',
          familyMemberId: 'p1',
          dosage: '1 Tablet',
          form: MedicineForm.tablet,
          instructions: MealInstruction.beforeFood,
          scheduledDateTime: DateTime(2025, 1, 15, 8, 0),
          status: MedicationLogStatus.taken,
          actionTime: DateTime(2025, 1, 15, 8, 2),
        );

        final csv = CsvExporter.generateDoseHistoryCsv([log], [member]);

        expect(csv.contains('Log ID,Scheduled Date,Scheduled Time'), isTrue);
        expect(csv.contains('Tanvir Ahmed'), isTrue);
        expect(csv.contains('Concor 5mg'), isTrue);
        expect(csv.contains('taken'), isTrue);
      },
    );
  });
}
