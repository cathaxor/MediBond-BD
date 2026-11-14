import '../../data/models/medication_log.dart';

class DoseStatistics {
  final int totalScheduled;
  final int takenCount;
  final int pendingCount;
  final int missedCount;
  final int skippedCount;
  final int overdueCount;

  DoseStatistics({
    required this.totalScheduled,
    required this.takenCount,
    required this.pendingCount,
    required this.missedCount,
    required this.skippedCount,
    required this.overdueCount,
  });

  /// Adherence rate as integer percentage (0-100)
  int get adherencePercentage {
    final eligible = totalScheduled - pendingCount;
    if (eligible <= 0) return totalScheduled > 0 && takenCount > 0 ? 100 : 0;
    return ((takenCount / eligible) * 100).round().clamp(0, 100);
  }

  static DoseStatistics calculate(List<MedicationLog> logs, {DateTime? now}) {
    final refTime = now ?? DateTime.now();

    int total = logs.length;
    int taken = 0;
    int pending = 0;
    int missed = 0;
    int skipped = 0;
    int overdue = 0;

    for (var l in logs) {
      switch (l.status) {
        case MedicationLogStatus.taken:
          taken++;
          break;
        case MedicationLogStatus.pending:
          pending++;
          if (l.scheduledDateTime.isBefore(
            refTime.subtract(const Duration(minutes: 30)),
          )) {
            overdue++;
          }
          break;
        case MedicationLogStatus.missed:
          missed++;
          break;
        case MedicationLogStatus.skipped:
          skipped++;
          break;
      }
    }

    return DoseStatistics(
      totalScheduled: total,
      takenCount: taken,
      pendingCount: pending,
      missedCount: missed,
      skippedCount: skipped,
      overdueCount: overdue,
    );
  }
}
