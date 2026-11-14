import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/medication_log.dart';
import '../../data/models/medicine.dart';
import '../../state/app_state_provider.dart';

class TimelineItemWidget extends ConsumerWidget {
  final MedicationLog log;
  final bool isLast;

  const TimelineItemWidget({super.key, required this.log, this.isLast = false});

  IconData _getFormIcon(MedicineForm form) {
    switch (form) {
      case MedicineForm.tablet:
        return Icons.medication_rounded;
      case MedicineForm.syrup:
        return Icons.water_drop_rounded;
      case MedicineForm.capsule:
        return Icons.medical_services_rounded;
      case MedicineForm.injection:
        return Icons.vaccines_rounded;
      case MedicineForm.drops:
        return Icons.opacity_rounded;
      default:
        return Icons.healing_rounded;
    }
  }

  Color _getStatusColor(MedicationLogStatus status) {
    switch (status) {
      case MedicationLogStatus.taken:
        return AppColors.success;
      case MedicationLogStatus.pending:
        return AppColors.warning;
      case MedicationLogStatus.missed:
        return AppColors.error;
      case MedicationLogStatus.skipped:
        return Colors.grey;
    }
  }

  String _getStatusText(MedicationLogStatus status, AppLocalizations? loc) {
    switch (status) {
      case MedicationLogStatus.taken:
        return loc?.translate('takenSummary') ?? 'Taken';
      case MedicationLogStatus.pending:
        return loc?.translate('pendingSummary') ?? 'Pending';
      case MedicationLogStatus.missed:
        return loc?.translate('missedSummary') ?? 'Missed';
      case MedicationLogStatus.skipped:
        return 'Skipped';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final timeStr = DateFormat('hh:mm a').format(log.scheduledDateTime);
    final appState = ref.watch(appStateProvider);
    final member = appState.members.firstWhere(
      (m) => m.id == log.familyMemberId,
      orElse: () => appState.members.first,
    );
    final statusColor = _getStatusColor(log.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  timeStr.split(' ')[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  timeStr.split(' ').length > 1 ? timeStr.split(' ')[1] : '',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha(100),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.borderLight),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: log.status == MedicationLogStatus.taken
                      ? AppColors.success.withAlpha(60)
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFormIcon(log.form),
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.medicineName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: log.status == MedicationLogStatus.taken
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${log.dosage} • ${member.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (log.status == MedicationLogStatus.pending)
                    IconButton.filledTonal(
                      onPressed: () {
                        ref
                            .read(appStateProvider.notifier)
                            .markLogStatus(log.id, MedicationLogStatus.taken);
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(log.status, loc),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
