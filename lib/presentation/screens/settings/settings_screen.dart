import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../state/app_state_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hideLockScreenNames = false;
  int _snoozeDurationMinutes = 10;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final themeState = ref.watch(themeSettingsProvider);
    final secState = ref.watch(securityControllerProvider);
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc?.translate('settings') ?? 'Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // My Profile Card
            _buildSectionHeader(
              context,
              'My Profile',
              Icons.account_circle_outlined,
            ),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      appState.primaryProfile?.avatarColor ?? AppColors.primary,
                  child: Text(
                    appState.primaryProfile?.avatarInitials ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  appState.primaryUserName.isNotEmpty
                      ? appState.primaryUserName
                      : 'Primary Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('View and edit personal & health profile'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/profile'),
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Theme Options
            _buildSectionHeader(
              context,
              loc?.translate('appearance') ?? 'Appearance & Theme',
              Icons.palette_outlined,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.brightness_6_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(loc?.translate('themeMode') ?? 'Theme Mode'),
                    subtitle: Text(
                      themeState.themeMode == ThemeMode.light
                          ? (loc?.translate('themeLight') ?? 'Light Mode')
                          : themeState.themeMode == ThemeMode.dark
                          ? (loc?.translate('themeDark') ?? 'Dark Mode')
                          : (loc?.translate('themeSystem') ?? 'System Default'),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeState.themeMode,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc?.translate('themeLight') ?? 'Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc?.translate('themeDark') ?? 'Dark'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(
                            loc?.translate('themeSystem') ?? 'System',
                          ),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref
                              .read(themeSettingsProvider.notifier)
                              .setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Accent Color Picker
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.color_lens_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Accent Color Theme',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    themeState.accentColor.displayName,
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: AppAccentColor.values.map((c) {
                            final isSel = themeState.accentColor == c;
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(themeSettingsProvider.notifier)
                                    .setAccentColor(c);
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: c.color,
                                child: isSel
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.language_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(loc?.translate('language') ?? 'Language'),
                    subtitle: Text(
                      locale.languageCode == 'bn'
                          ? (loc?.translate('bangla') ?? 'বাংলা (Bangla)')
                          : (loc?.translate('english') ?? 'English'),
                    ),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('EN')),
                        ButtonSegment(value: 'bn', label: Text('বাং')),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (set) {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(set.first, ''));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Encrypted Data & Backup Section
            _buildSectionHeader(
              context,
              'Encrypted Data & Backup',
              Icons.shield_moon_outlined,
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.save_alt_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Data & Encrypted Backup'),
                subtitle: const Text(
                  'Export and restore password-encrypted .medibond files',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/data-backup'),
              ),
            ),
            const SizedBox(height: 20),

            // App Updates Section
            _buildSectionHeader(
              context,
              'App Version & Updates',
              Icons.system_update_rounded,
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('App Updates'),
                subtitle: const Text(
                  'Check for new releases and minimum build status',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/app-updates'),
              ),
            ),
            const SizedBox(height: 20),

            // Account & Security Section
            _buildSectionHeader(
              context,
              'MediBond Account',
              Icons.manage_accounts_outlined,
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.cloud_done_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Account & Security'),
                subtitle: const Text('Manage email, password & auth session'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/account-settings'),
              ),
            ),
            const SizedBox(height: 20),

            // App Security & Lock Section
            _buildSectionHeader(
              context,
              'App Security & Lock',
              Icons.shield_outlined,
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('App Lock (PIN / Biometric)'),
                    subtitle: const Text('Require authentication to open app'),
                    value: secState.isAppLockEnabled,
                    onChanged: (val) {
                      ref
                          .read(securityControllerProvider.notifier)
                          .setAppLockEnabled(val);
                    },
                  ),
                  if (secState.isAppLockEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.timer_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Inactivity Timeout'),
                      subtitle: Text(
                        '${secState.inactivityTimeoutMinutes} minute(s)',
                      ),
                      trailing: DropdownButton<int>(
                        value: secState.inactivityTimeoutMinutes,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 min')),
                          DropdownMenuItem(value: 5, child: Text('5 mins')),
                          DropdownMenuItem(value: 15, child: Text('15 mins')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(securityControllerProvider.notifier)
                                .setInactivityTimeout(val);
                          }
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.security_update_warning_outlined,
                      color: AppColors.warning,
                    ),
                    title: const Text('Security Assessment & Disclosure'),
                    subtitle: const Text(
                      'View unresolved security risks & design limits',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showSecurityAssessmentDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications & Reminders
            _buildSectionHeader(
              context,
              loc?.translate('notifications') ?? 'Notifications & Reminders',
              Icons.notifications_outlined,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                    title: const Text('Notification Status'),
                    subtitle: const Text('Active & Configured'),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(90, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () {
                        NotificationService().requestPermissions();
                      },
                      child: const Text(
                        'Permissions',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      loc?.translate('notificationPrivacy') ??
                          'Lock Screen Privacy',
                    ),
                    subtitle: Text(
                      loc?.translate('hideMedNamesLockScreen') ??
                          'Hide medicine names on lock screen',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _hideLockScreenNames,
                    onChanged: (val) {
                      setState(() {
                        _hideLockScreenNames = val;
                      });
                      NotificationService().setPrivacyOption(val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.snooze_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      loc?.translate('snoozeDuration') ?? 'Snooze Duration',
                    ),
                    subtitle: Text('$_snoozeDurationMinutes minutes'),
                    trailing: DropdownButton<int>(
                      value: _snoozeDurationMinutes,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 mins')),
                        DropdownMenuItem(value: 10, child: Text('10 mins')),
                        DropdownMenuItem(value: 15, child: Text('15 mins')),
                        DropdownMenuItem(value: 30, child: Text('30 mins')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _snoozeDurationMinutes = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Demo Data & Storage Reset
            _buildSectionHeader(
              context,
              loc?.translate('demoDataNotice') ?? 'Local Data Wipe',
              Icons.delete_forever_outlined,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear all local encrypted database records and local storage files permanently.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () {
                        ref.read(appStateProvider.notifier).resetToDemoData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc?.translate('resetDemoData') ??
                                  'Demo data reset',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        loc?.translate('resetDemoData') ?? 'Reset Local Data',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About & Support
            _buildSectionHeader(
              context,
              loc?.translate('aboutApp') ?? 'About & Support',
              Icons.info_outline_rounded,
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.person_pin_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Developer & Product Info'),
                    subtitle: const Text('Abdur Rahaman Abdulla (CatHaxor)'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/developer-info'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.business_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      loc?.translate('aboutNethivo') ?? 'About Nethivo',
                    ),
                    subtitle: const Text(
                      'Nethivo Health Systems • Organization: com.nethivo',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      loc?.translate('privacyPolicy') ?? 'Privacy Policy',
                    ),
                    subtitle: const Text(
                      '100% Offline & Private Local Storage',
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () => _showPrivacyPolicyDialog(context, loc),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.contact_support_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      loc?.translate('supportContact') ?? 'Support & Contact',
                    ),
                    subtitle: Text(
                      loc?.translate('supportEmail') ?? 'support@nethivo.com',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Security Assessment & Disclosure'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Security Hardening Measures Implemented:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '• Database notes & vault files encrypted at rest.\n'
                '• Encryption keys secured via Android Keystore.\n'
                '• OS Cloud backups disabled (allowBackup="false").\n'
                '• Background task switcher privacy shield enabled.\n'
                '• Lock screen notification privacy controls.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              SizedBox(height: 14),
              Text(
                'Explicit Unresolved Security Risks:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '1. Rooted / Compromised Devices: Malware running with root access on a compromised Android device could theoretically inspect application memory space.\n'
                '2. System Backup Loss: Because OS cloud backup is explicitly disabled for privacy, factory resetting a device without exporting data will cause permanent data loss.\n'
                '3. Physical Device Access: If a user leaves their device unlocked and App Lock is disabled, physical access to the device exposes open screens.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Understand & Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context, AppLocalizations? loc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          loc?.translate('privacyPolicy') ?? 'MediBond BD Privacy Policy',
        ),
        content: const SingleChildScrollView(
          child: Text(
            'All family profiles, medication schedules, dose histories, and uploaded prescription documents are stored 100% locally on your device in encrypted SQLite databases.\n\n'
            'MediBond BD does not perform automatic cloud uploads, telemetry, or remote data analytics. Your health data stays on your device.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
