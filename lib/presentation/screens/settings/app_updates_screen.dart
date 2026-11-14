import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/app_release_service.dart';
import '../../widgets/app_update_dialog.dart';

class AppUpdatesScreen extends ConsumerWidget {
  const AppUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final releaseState = ref.watch(appReleaseProvider);
    final controller = ref.read(appReleaseProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('appUpdates') ?? 'App Version & Updates'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Installed Version Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MediBond BD',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Installed Version: ${releaseState.currentVersion} (Build ${releaseState.currentBuild})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    _buildDetailRow(
                      'App Package ID',
                      'com.nethivo.medibond_bd',
                    ),
                    _buildDetailRow('Release Channel', 'Production (Android)'),
                    _buildDetailRow(
                      'Last Update Check',
                      releaseState.lastCheckTime != null
                          ? DateFormat('dd MMM yyyy, hh:mm a')
                                .format(releaseState.lastCheckTime!)
                          : 'Not checked yet',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Version Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remote Version Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (releaseState.isLoading) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Checking release server...',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ] else if (releaseState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                releaseState.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (releaseState.latestRelease != null) ...[
                      _buildDetailRow(
                        'Latest Server Version',
                        '${releaseState.latestRelease!.versionName} (Build ${releaseState.latestRelease!.buildNumber})',
                      ),
                      _buildDetailRow(
                        'Minimum Supported Build',
                        '${releaseState.latestRelease!.minimumSupportedBuild}',
                      ),
                      _buildDetailRow(
                        'Update Status',
                        releaseState.isUpdateAvailable
                            ? (releaseState.isMandatoryUpdate
                                  ? 'Required Update Available'
                                  : 'Optional Update Available')
                            : 'App is up to date',
                      ),
                    ] else ...[
                      const Text(
                        'No release records fetched yet. Tap "Check for Updates" below.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: releaseState.isLoading
                          ? null
                          : () async {
                              await controller.checkForUpdates(isManual: true);
                              final updatedState = ref.read(appReleaseProvider);
                              if (context.mounted) {
                                if (updatedState.isUpdateAvailable &&
                                    updatedState.latestRelease != null) {
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AppUpdateDialog(
                                      release: updatedState.latestRelease!,
                                      isMandatory:
                                          updatedState.isMandatoryUpdate,
                                    ),
                                  );
                                } else if (updatedState.errorMessage == null &&
                                    !updatedState.isUpdateAvailable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You are running the latest version of MediBond BD!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Check for Updates Now'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Distribution Policy Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Official Distribution Policy: Updates are served through verified Play Store or HTTPS distribution links. MediBond BD never silently installs APK files or downloads executable binaries.',
                        style: TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
