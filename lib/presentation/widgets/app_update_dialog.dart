import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/supabase/app_release_service.dart';

class AppUpdateDialog extends ConsumerWidget {
  final AppRelease release;
  final bool isMandatory;

  const AppUpdateDialog({
    super.key,
    required this.release,
    required this.isMandatory,
  });

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final uri = Uri.parse(release.updateUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch update URL: ${release.updateUrl}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching update link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isBn = locale.languageCode == 'bn';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !isMandatory,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMandatory
                        ? (isBn
                              ? 'জরুরি অ্যাপ আপডেট'
                              : 'Required Application Update')
                        : (isBn
                              ? 'নতুন আপডেট পাওয়া গেছে'
                              : 'New Update Available'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isMandatory ? AppColors.error : AppColors.primary,
                    ),
                  ),
                  Text(
                    'Version ${release.versionName} (Build ${release.buildNumber})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMandatory) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isBn
                              ? 'আপনার ইনস্টল করা সংস্করণটি বেশ পুরোনো। সেরা অভিজ্ঞতা এবং নিরাপত্তার জন্য নতুন সংস্করণে আপডেট করুন।'
                              : 'Your installed version is below the minimum supported build. Please update for optimal app compatibility.',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (release.releaseNotes.isNotEmpty) ...[
                Text(
                  isBn ? 'এই সংস্করণের পরিবর্তনসমূহ:' : 'What\'s New:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.primaryContainer.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    release.releaseNotes,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Medication User Emergency Continuity Guarantee
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? 'আপনার স্থানীয় ওষুধের তালিকা এবং রিমাইন্ডার সবসময় সচল থাকবে।'
                            : 'Your local offline medication schedule & dose reminders remain 100% active.',
                        style: const TextStyle(fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () {
                ref.read(appReleaseProvider.notifier).markDialogShown();
                Navigator.pop(context);
              },
              child: Text(isBn ? 'পরে আপডেট করব' : 'Remind Me Later'),
            ),

          if (isMandatory)
            TextButton(
              onPressed: () {
                ref.read(appReleaseProvider.notifier).markDialogShown();
                Navigator.pop(context);
              },
              child: Text(
                isBn
                    ? 'ওষুধের তালিকায় যান (অফলাইন)'
                    : 'Continue Offline Schedule',
                style: const TextStyle(fontSize: 12),
              ),
            ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _launchUpdateUrl(context),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(
              isBn ? 'এখনই আপডেট করুন' : 'Update Now',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
