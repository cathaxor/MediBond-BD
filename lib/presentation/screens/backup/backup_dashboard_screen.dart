import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/security/backup_service.dart';
import '../../../core/supabase/auth_controller.dart';
import '../../../state/app_state_provider.dart';

class BackupDashboardScreen extends ConsumerStatefulWidget {
  const BackupDashboardScreen({super.key});

  @override
  ConsumerState<BackupDashboardScreen> createState() =>
      _BackupDashboardScreenState();
}

class _BackupDashboardScreenState extends ConsumerState<BackupDashboardScreen> {
  bool _isExporting = false;
  bool _isRestoring = false;

  Future<void> _handleCreateBackup() async {
    final authState = ref.read(authControllerProvider);
    final userId = authState.user?.id ?? 'offline_local_user';

    final password = await _showPasswordDialog(
      context: context,
      title: 'Set Backup Encryption Password',
      confirmRequired: true,
      hint: 'Create a strong password. This password will be required to decrypt and restore your .medibond backup file.',
    );

    if (password == null || password.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isExporting = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final backupBytes = await backupService.createEncryptedBackup(
        password: password.trim(),
        userId: userId,
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final filename = 'MediBond_Backup_$dateStr.medibond';

      String? outputPath;
      try {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Encrypted Backup (.medibond)',
          fileName: filename,
          bytes: backupBytes,
        );
      } catch (_) {}

      if (outputPath == null) {
        final docsDir = await getApplicationDocumentsDirectory();
        final localFile = File('${docsDir.path}/$filename');
        await localFile.writeAsBytes(backupBytes);
        outputPath = localFile.path;
      }

      if (mounted) {
        setState(() => _isExporting = false);
        _showSuccessDialog(
          context: context,
          title: 'Backup Created Successfully',
          message:
              'Encrypted backup saved to:\n$outputPath\n\nFile Size: ${(backupBytes.length / 1024).toStringAsFixed(1)} KB\n\nKeep your backup password safe. It cannot be recovered if forgotten.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorDialog(
          context: context,
          title: 'Backup Creation Failed',
          message: e.toString(),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup() async {
    final authState = ref.read(authControllerProvider);
    final activeUserId = authState.user?.id ?? 'offline_local_user';

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    Uint8List? fileBytes = pickedFile.bytes;

    if (fileBytes == null && pickedFile.path != null) {
      fileBytes = await File(pickedFile.path!).readAsBytes();
    }

    if (fileBytes == null) {
      if (mounted) {
        _showErrorDialog(
          context: context,
          title: 'File Read Error',
          message: 'Unable to read selected backup file.',
        );
      }
      return;
    }

    if (!mounted) return;
    final password = await _showPasswordDialog(
      context: context,
      title: 'Enter Backup Password',
      confirmRequired: false,
      hint: 'Enter the encryption password used when this .medibond backup was created.',
    );

    if (password == null || password.trim().isEmpty) return;

    if (!mounted) return;
    setState(() => _isRestoring = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final preview = await backupService.previewEncryptedBackup(
        backupBytes: fileBytes,
        password: password.trim(),
        activeUserId: activeUserId,
      );

      if (!mounted) return;
      setState(() => _isRestoring = false);

      final selectedMode = await _showRestorePreviewDialog(
        context: context,
        preview: preview,
      );

      if (selectedMode == null) return;

      if (!mounted) return;
      setState(() => _isRestoring = true);

      await backupService.restoreBackupData(
        preview: preview,
        mode: selectedMode,
      );

      await ref.read(appStateProvider.notifier).loadFromDatabase();

      if (mounted) {
        setState(() => _isRestoring = false);
        _showSuccessDialog(
          context: context,
          title: 'Restoration Completed',
          message:
              'Successfully restored:\n• ${preview.profilesCount} Family Profile(s)\n• ${preview.medicinesCount} Medicine Record(s)\n• ${preview.doseLogsCount} Dose Event(s)\n• ${preview.prescriptionsCount} Prescription(s)\n\nUpcoming medicine reminders reconciled.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        _showErrorDialog(
          context: context,
          title: 'Restoration Failed',
          message: e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('StateError: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('dataBackup') ?? 'Data & Encrypted Backup'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Create Backup Card
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
                            Icons.shield_moon_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Encrypted Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Export .medibond encrypted file',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Export your profiles, medicines, schedules, dose history, and prescription documents into a password-encrypted .medibond archive using AES-256-GCM and PBKDF2 key derivation (100,000 iterations).',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleCreateBackup,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isExporting
                            ? 'Creating Encrypted Backup...'
                            : 'Create Encrypted Backup (.medibond)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Restore Backup Card
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
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restore_page_outlined,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restore Encrypted Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Import & decrypt .medibond file',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Select an existing .medibond backup file and enter the backup encryption password to decrypt and restore healthcare records.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _isRestoring ? null : _handleRestoreBackup,
                      icon: _isRestoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_rounded),
                      label: Text(
                        _isRestoring
                            ? 'Decrypting Backup...'
                            : 'Select .medibond File & Restore',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Data Security Disclosure Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Offline Security Guarantee: MediBond BD backups are 100% offline. Backup files and encryption passwords are never uploaded to Supabase or cloud servers.',
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

  Future<String?> _showPasswordDialog({
    required BuildContext context,
    required String title,
    required bool confirmRequired,
    required String hint,
  }) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Backup Password *',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() => obscure = !obscure);
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (confirmRequired) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscure,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: Icon(Icons.lock_clock_outlined),
                      ),
                      validator: (val) {
                        if (val != passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogCtx, passwordCtrl.text.trim());
                }
              },
              child: const Text('Confirm Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<RestoreMode?> _showRestorePreviewDialog({
    required BuildContext context,
    required BackupPreviewData preview,
  }) async {
    return showDialog<RestoreMode>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Backup Contents Preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(preview.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(
                      'Family Profiles',
                      '${preview.profilesCount}',
                    ),
                    _buildPreviewRow('Medicines', '${preview.medicinesCount}'),
                    _buildPreviewRow('Dose Logs', '${preview.doseLogsCount}'),
                    _buildPreviewRow(
                      'Prescriptions',
                      '${preview.prescriptionsCount}',
                    ),
                    _buildPreviewRow('Vault Files', '${preview.filesCount}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Restore Option:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, RestoreMode.merge),
            child: const Text('Merge Non-Duplicates'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(dialogCtx, RestoreMode.replace),
            child: const Text('Replace Local Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            count,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.error)),
        content: Text(message),
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
