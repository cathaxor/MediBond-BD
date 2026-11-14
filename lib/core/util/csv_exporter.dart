import 'package:intl/intl.dart';

import '../../data/models/family_member.dart';
import '../../data/models/medication_log.dart';

class CsvExporter {
  /// Generates a clean CSV formatted text string for local export/saving
  static String generateDoseHistoryCsv(
    List<MedicationLog> logs,
    List<FamilyMember> members,
  ) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'Log ID,Scheduled Date,Scheduled Time,Member Name,Medicine Name,Dosage,Status,Action Time',
    );

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (var log in logs) {
      final member = members.firstWhere(
        (m) => m.id == log.familyMemberId,
        orElse: () => members.isNotEmpty
            ? members.first
            : _dummyMember(log.familyMemberId),
      );

      final scheduledDate = dateFormat.format(log.scheduledDateTime);
      final scheduledTime = timeFormat.format(log.scheduledDateTime);
      final actionTimeStr = log.actionTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(log.actionTime!)
          : 'N/A';

      final cleanMedicine = _escapeCsv(log.medicineName);
      final cleanMember = _escapeCsv(member.name);
      final cleanDosage = _escapeCsv(log.dosage);

      buffer.writeln(
        '${log.id},$scheduledDate,$scheduledTime,"$cleanMember","$cleanMedicine","$cleanDosage",${log.status.name},$actionTimeStr',
      );
    }

    return buffer.toString();
  }

  static String _escapeCsv(String text) {
    return text.replaceAll('"', '""');
  }

  static FamilyMember _dummyMember(String id) {
    return FamilyMember(
      id: id,
      name: 'Member',
      relationship: 'Self',
      relationshipBn: 'আমি',
      age: 30,
      bloodGroup: 'O+',
      avatarInitials: 'M',
      avatarColorValue: 0xFF087F79,
      emergencyContact: '',
    );
  }
}
