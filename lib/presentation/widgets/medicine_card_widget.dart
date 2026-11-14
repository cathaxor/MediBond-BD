import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/medicine.dart';
import '../../state/app_state_provider.dart';

class MedicineCardWidget extends ConsumerWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCardWidget({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

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

  String _getFormText(MedicineForm form, AppLocalizations? loc) {
    switch (form) {
      case MedicineForm.tablet:
        return loc?.translate('tablet') ?? 'Tablet';
      case MedicineForm.capsule:
        return loc?.translate('capsule') ?? 'Capsule';
      case MedicineForm.liquid:
      case MedicineForm.syrup:
        return loc?.translate('syrup') ?? 'Liquid / Syrup';
      case MedicineForm.injection:
        return loc?.translate('injection') ?? 'Injection';
      case MedicineForm.drops:
        return loc?.translate('drops') ?? 'Drops';
      case MedicineForm.ointment:
        return loc?.translate('ointment') ?? 'Ointment';
      default:
        return loc?.translate('other') ?? 'Other';
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
      (m) => m.id == medicine.familyMemberId,
      orElse: () => appState.members.first,
    );
    final color = Color(medicine.colorHex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFormIcon(medicine.form),
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              medicine.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (medicine.isPaused) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Paused',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${medicine.strength.isNotEmpty ? "${medicine.strength} • " : ""}${_getFormText(medicine.form, loc)} • ${medicine.dosage} • ${_getInstructionText(medicine.instructions, loc)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'pause') {
                        ref
                            .read(appStateProvider.notifier)
                            .togglePauseMedicine(medicine.id);
                      }
                      if (val == 'archive') {
                        ref
                            .read(appStateProvider.notifier)
                            .toggleArchiveMedicine(medicine.id);
                      }
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              loc?.translate('editMedicine') ?? 'Edit Medicine',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pause',
                        child: Row(
                          children: [
                            Icon(
                              medicine.isPaused
                                  ? Icons.play_arrow_outlined
                                  : Icons.pause_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              medicine.isPaused
                                  ? 'Resume Tracking'
                                  : 'Pause Tracking',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              medicine.isActive
                                  ? Icons.archive_outlined
                                  : Icons.unarchive_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(medicine.isActive ? 'Archive' : 'Restore'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loc?.translate('deleteMedicine') ??
                                  'Delete Medicine',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: member.avatarColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: member.avatarColor.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: member.avatarColor,
                          child: Text(
                            member.avatarInitials,
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          member.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: member.avatarColor,
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
                      color: medicine.isLowStock
                          ? AppColors.errorContainer
                          : AppColors.successContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          medicine.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_outlined,
                          size: 14,
                          color: medicine.isLowStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${medicine.stockCount} ${loc?.translate('stockLeft') ?? "left"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: medicine.isLowStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
