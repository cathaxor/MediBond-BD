import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';

class StatSummaryWidget extends StatelessWidget {
  final int taken;
  final int pending;
  final int missed;

  const StatSummaryWidget({
    super.key,
    required this.taken,
    required this.pending,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            context: context,
            count: taken,
            label: loc?.translate('takenSummary') ?? 'Taken',
            color: AppColors.success,
            icon: Icons.check_circle_outline_rounded,
          ),
          _buildDivider(),
          _buildItem(
            context: context,
            count: pending,
            label: loc?.translate('pendingSummary') ?? 'Pending',
            color: AppColors.warning,
            icon: Icons.hourglass_top_rounded,
          ),
          _buildDivider(),
          _buildItem(
            context: context,
            count: missed,
            label: loc?.translate('missedSummary') ?? 'Missed',
            color: AppColors.error,
            icon: Icons.error_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: AppColors.borderLight);
  }
}
