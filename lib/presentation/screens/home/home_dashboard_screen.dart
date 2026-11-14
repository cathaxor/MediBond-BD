import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../data/models/medication_log.dart';
import '../../../state/app_state_provider.dart';
import '../../widgets/next_reminder_card_widget.dart';
import '../../widgets/profile_selector_widget.dart';
import '../../widgets/stat_summary_widget.dart';
import '../../widgets/timeline_item_widget.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  String _getGreeting(AppLocalizations? loc) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return loc?.translate('goodMorning') ?? 'Good Morning,';
    } else if (hour < 17) {
      return loc?.translate('goodAfternoon') ?? 'Good Afternoon,';
    } else {
      return loc?.translate('goodEvening') ?? 'Good Evening,';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final syncState = ref.watch(syncServiceProvider);
    final nextLog = ref.watch(nextPendingLogProvider);
    final filteredLogs = ref.watch(filteredLogsProvider);
    final filteredMeds = ref.watch(filteredMedicinesProvider);
    final todayStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    final activeName = appState.activeUserName;

    // Filter logs for today
    final now = DateTime.now();
    final todayLogs = filteredLogs.where((l) {
      return l.scheduledDateTime.year == now.year &&
          l.scheduledDateTime.month == now.month &&
          l.scheduledDateTime.day == now.day;
    }).toList();
    todayLogs.sort(
      (a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime),
    );

    final takenCount = todayLogs
        .where((l) => l.status == MedicationLogStatus.taken)
        .length;
    final pendingCount = todayLogs
        .where((l) => l.status == MedicationLogStatus.pending)
        .length;
    final missedCount = todayLogs
        .where((l) => l.status == MedicationLogStatus.missed)
        .length;

    final hasNoMeds = filteredMeds.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeName.isNotEmpty
                  ? '${_getGreeting(loc)} $activeName'
                  : _getGreeting(loc).replaceAll(',', ''),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              todayStr,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Cloud Data',
            onPressed: () {
              ref.read(syncServiceProvider.notifier).syncAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronizing records with cloud...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(
              syncState.status == SyncStatus.syncing
                  ? Icons.sync_rounded
                  : syncState.status == SyncStatus.synced
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_queue_rounded,
              color: syncState.status == SyncStatus.synced
                  ? AppColors.primary
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'My Profile',
            onPressed: () {
              context.push('/profile');
            },
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip:
                loc?.translate('prescriptionVault') ?? 'Prescription Vault',
            onPressed: () {
              context.push('/prescription-vault');
            },
            icon: const Icon(Icons.folder_special_outlined),
          ),
          IconButton(
            tooltip: loc?.translate('settings') ?? 'Settings',
            onPressed: () {
              context.push('/settings');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSelectorWidget(),
              const SizedBox(height: 8),

              // Empty Medicine State or Next Reminder Card
              if (hasNoMeds)
                _buildEmptyMedsCard(context, loc)
              else if (nextLog != null)
                NextReminderCardWidget(log: nextLog)
              else
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          loc?.translate('noMedsToday') ??
                              'No pending medicines remaining for today!',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              StatSummaryWidget(
                taken: takenCount,
                pending: pendingCount,
                missed: missedCount,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc?.translate('todayTimeline') ??
                          "Today's Medication Timeline",
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontSize: 18),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        context.push('/add-edit-medicine');
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        loc?.translate('quickAddMed') ?? 'Add Medicine',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (todayLogs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      hasNoMeds
                          ? 'No medicines added yet'
                          : (loc?.translate('noMedsToday') ??
                                'No medicines scheduled for today.'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayLogs.length,
                    itemBuilder: (context, index) {
                      return TimelineItemWidget(
                        log: todayLogs[index],
                        isLast: index == todayLogs.length - 1,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMedsCard(BuildContext context, AppLocalizations? loc) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No medicines added yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your medication schedule to receive offline reminders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/add-edit-medicine');
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Your First Medicine'),
          ),
        ],
      ),
    );
  }
}
