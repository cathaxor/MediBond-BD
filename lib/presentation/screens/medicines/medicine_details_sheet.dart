import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/medicine.dart';
import '../../../state/app_state_provider.dart';

class MedicineDetailsSheet extends ConsumerWidget {
  final Medicine medicine;
  final VoidCallback onEdit;

  const MedicineDetailsSheet({
    super.key,
    required this.medicine,
    required this.onEdit,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final member = appState.members.firstWhere(
      (m) => m.id == medicine.familyMemberId,
      orElse: () => appState.members.first,
    );
    final color = Color(medicine.colorHex);
    final startDateStr = DateFormat('dd MMM yyyy').format(medicine.startDate);
    final endDateStr = medicine.endDate != null
        ? DateFormat('dd MMM yyyy').format(medicine.endDate!)
        : 'Ongoing';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFormIcon(medicine.form),
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (medicine.strength.isNotEmpty)
                      Text(
                        'Strength: ${medicine.strength}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    Text(
                      '${_getFormText(medicine.form, loc)} • ${medicine.dosage}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Detail rows
          _buildDetailRow(
            context,
            icon: Icons.person_outline_rounded,
            label: 'Assigned Profile',
            value: member.name,
          ),
          _buildDetailRow(
            context,
            icon: Icons.inventory_2_outlined,
            label: 'Stock Remaining',
            value:
                '${medicine.stockCount} left (Alert threshold: ${medicine.reorderThreshold})',
          ),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Duration',
            value: '$startDateStr — $endDateStr',
          ),
          _buildDetailRow(
            context,
            icon: Icons.access_time_rounded,
            label: 'Reminder Times',
            value: medicine.scheduledTimes
                .map((t) => t.format(context))
                .join(', '),
          ),
          if (medicine.notes.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.notes_rounded,
              label: 'Notes / Instructions',
              value: medicine.notes,
            ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(appStateProvider.notifier)
                        .togglePauseMedicine(medicine.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    medicine.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(
                    medicine.isPaused ? 'Resume Tracking' : 'Pause Tracking',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: medicine.isActive
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                  onPressed: () {
                    ref
                        .read(appStateProvider.notifier)
                        .toggleArchiveMedicine(medicine.id);
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    medicine.isActive
                        ? Icons.archive_outlined
                        : Icons.unarchive_outlined,
                  ),
                  label: Text(medicine.isActive ? 'Archive' : 'Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
