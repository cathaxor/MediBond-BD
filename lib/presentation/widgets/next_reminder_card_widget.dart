import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/medication_log.dart';
import '../../data/models/medicine.dart';
import '../../state/app_state_provider.dart';

class NextReminderCardWidget extends ConsumerWidget {
  final MedicationLog log;

  const NextReminderCardWidget({super.key, required this.log});

  IconData _getFormIcon(MedicineForm form) {
    switch (form) {
      case MedicineForm.tablet:
        return Icons.medication_rounded;
      case MedicineForm.capsule:
        return Icons.medical_services_rounded;
      case MedicineForm.liquid:
      case MedicineForm.syrup:
        return Icons.water_drop_rounded;
      case MedicineForm.injection:
        return Icons.vaccines_rounded;
      case MedicineForm.drops:
        return Icons.opacity_rounded;
      case MedicineForm.ointment:
        return Icons.sanitizer_rounded;
      default:
        return Icons.healing_rounded;
    }
  }

  String _getInstructionText(
    MealInstruction instruction,
    AppLocalizations? loc,
  ) {
    switch (instruction) {
      case MealInstruction.beforeFood:
        return loc?.translate('beforeFood') ?? 'Before Food';
      case MealInstruction.afterFood:
        return loc?.translate('afterFood') ?? 'After Food';
      case MealInstruction.withFood:
        return loc?.translate('withFood') ?? 'With Food';
      case MealInstruction.anytime:
        return loc?.translate('anytime') ?? 'Any Time';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final member = appState.members.firstWhere(
      (m) => m.id == log.familyMemberId,
      orElse: () => appState.members.first,
    );
    final timeStr = DateFormat('hh:mm a').format(log.scheduledDateTime);

    return Semantics(
      label:
          'Next Medicine Reminder: ${log.medicineName}, ${log.dosage}, scheduled for $timeStr for ${member.name}',
      button: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF065A55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(80),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.health_and_safety_rounded,
                size: 140,
                color: Colors.white.withAlpha(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alarm_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              loc?.translate('nextReminder') ??
                                  'Next Medicine Reminder',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: member.avatarColor.withAlpha(220),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getFormIcon(log.form),
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.medicineName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${log.dosage} • ${_getInstructionText(log.instructions, loc)}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Take medicine ${log.medicineName} now',
                          button: true,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              ref
                                  .read(appStateProvider.notifier)
                                  .markLogStatus(
                                    log.id,
                                    MedicationLogStatus.taken,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${log.medicineName} - ${loc?.translate('markedTaken') ?? "Marked as Taken"}',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              size: 20,
                            ),
                            label: Text(
                              loc?.translate('takeNow') ?? 'Take Now',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        label: 'Snooze reminder 10 minutes',
                        button: true,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(110, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc?.translate('snooze') ?? 'Snooze 10m',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.snooze_rounded, size: 18),
                          label: Text(
                            loc?.translate('snooze') ?? 'Snooze',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
