import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/medicine.dart';
import '../../../state/app_state_provider.dart';
import '../../widgets/medicine_card_widget.dart';
import '../../widgets/profile_selector_widget.dart';
import 'medicine_details_sheet.dart';

class MedicinesListScreen extends ConsumerStatefulWidget {
  const MedicinesListScreen({super.key});

  @override
  ConsumerState<MedicinesListScreen> createState() =>
      _MedicinesListScreenState();
}

class _MedicinesListScreenState extends ConsumerState<MedicinesListScreen> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Active, 1: Archived

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final medicines = ref.watch(filteredMedicinesProvider);

    final filtered = medicines.where((m) {
      final matchesSearch =
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.strength.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTab = _selectedTab == 0 ? m.isActive : !m.isActive;
      return matchesSearch && matchesTab;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('medicinesList') ?? 'Medicines Cabinet'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/add-edit-medicine');
            },
            icon: const Icon(Icons.add_rounded),
            tooltip: loc?.translate('addMedicine') ?? 'Add Medicine',
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
                      loc?.translate('searchMedicines') ??
                      'Search medicine name...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Profile Selector
            const ProfileSelectorWidget(),
            const SizedBox(height: 8),

            // Filter Tabs (Active / Archived)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          loc?.translate('activeMeds') ?? 'Active',
                          style: TextStyle(
                            fontWeight: _selectedTab == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      selected: _selectedTab == 0,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (_) => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          'Archived',
                          style: TextStyle(
                            fontWeight: _selectedTab == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      selected: _selectedTab == 1,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (_) => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Medicines List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 0 && medicines.isEmpty
                                ? 'No medicines added yet'
                                : _selectedTab == 0
                                ? 'No active medicines found.'
                                : 'No archived medicines.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedTab == 0 && medicines.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push('/add-edit-medicine');
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Your First Medicine'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final medicine = filtered[index];
                        return MedicineCardWidget(
                          medicine: medicine,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => MedicineDetailsSheet(
                                medicine: medicine,
                                onEdit: () {
                                  context.push(
                                    '/add-edit-medicine',
                                    extra: medicine,
                                  );
                                },
                              ),
                            );
                          },
                          onEdit: () {
                            context.push('/add-edit-medicine', extra: medicine);
                          },
                          onDelete: () {
                            _showDeleteDialog(context, medicine);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Medicine medicine) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.translate('deleteMedicine') ?? 'Delete Medicine'),
        content: Text(
          loc?.translate('deleteConfirm') ??
              'Are you sure you want to delete this medicine?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc?.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appStateProvider.notifier).deleteMedicine(medicine.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medicine.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              loc?.translate('delete') ?? 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
