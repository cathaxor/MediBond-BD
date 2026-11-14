import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/prescription.dart';
import '../../../state/app_state_provider.dart';
import '../../widgets/prescription_card_widget.dart';
import '../../widgets/profile_selector_widget.dart';

class PrescriptionVaultScreen extends ConsumerStatefulWidget {
  const PrescriptionVaultScreen({super.key});

  @override
  ConsumerState<PrescriptionVaultScreen> createState() =>
      _PrescriptionVaultScreenState();
}

class _PrescriptionVaultScreenState
    extends ConsumerState<PrescriptionVaultScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final selectedId = appState.selectedFamilyMemberId;

    var list = selectedId == 'all'
        ? appState.prescriptions
        : appState.prescriptions
              .where((p) => p.familyMemberId == selectedId)
              .toList();

    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final q = _searchQuery.toLowerCase();
        return p.title.toLowerCase().contains(q) ||
            p.doctorName.toLowerCase().contains(q) ||
            p.hospitalName.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc?.translate('prescriptionVault') ?? 'Prescription Vault',
        ),
        actions: [
          IconButton(
            onPressed: () => _showUploadModal(context, ref),
            icon: const Icon(Icons.upload_file_rounded),
            tooltip:
                loc?.translate('uploadPrescription') ?? 'Upload Prescription',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText:
                      loc?.translate('searchVault') ??
                      'Search doctor, hospital, diagnosis...',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Profile Filter
            const ProfileSelectorWidget(),
            const SizedBox(height: 8),

            // Prescriptions List
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_off_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc?.translate('noPrescriptions') ??
                                'No prescriptions uploaded yet.',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return PrescriptionCardWidget(
                          prescription: list[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadModal(context, ref),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: Text(loc?.translate('uploadPrescription') ?? 'Upload'),
      ),
    );
  }

  void _showUploadModal(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final titleCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc?.translate('uploadPrescription') ?? 'Upload Prescription',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prescription Title',
                  hintText: 'e.g. Cardiology Visit',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doctorCtrl,
                decoration: InputDecoration(
                  labelText: loc?.translate('doctorName') ?? 'Doctor Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hospitalCtrl,
                decoration: InputDecoration(
                  labelText:
                      loc?.translate('hospitalClinic') ?? 'Hospital / Clinic',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: loc?.translate('notes') ?? 'Notes / Diagnosis',
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Tap to attach document / photo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final appState = ref.read(appStateProvider);
                  final targetMemberId =
                      appState.activeProfile?.id ??
                      appState.primaryProfile?.id ??
                      '';

                  final rx = Prescription(
                    id: 'pres_${DateTime.now().millisecondsSinceEpoch}',
                    title: titleCtrl.text.trim(),
                    doctorName: doctorCtrl.text.trim().isEmpty
                        ? 'Attending Physician'
                        : doctorCtrl.text.trim(),
                    hospitalName: hospitalCtrl.text.trim().isEmpty
                        ? 'Medical Clinic'
                        : hospitalCtrl.text.trim(),
                    date: DateTime.now(),
                    familyMemberId: targetMemberId,
                    notes: notesCtrl.text.trim(),
                    tags: const ['General', 'Prescription'],
                  );
                  ref.read(appStateProvider.notifier).addPrescription(rx);
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prescription uploaded successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save to Vault'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
