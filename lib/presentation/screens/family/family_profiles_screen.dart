import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/family_member.dart';
import '../../../state/app_state_provider.dart';

class FamilyProfilesScreen extends ConsumerWidget {
  const FamilyProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final selectedId = appState.selectedFamilyMemberId;
    final members = appState.members;
    final medicines = appState.medicines;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('familyProfiles') ?? 'Family Profiles'),
        actions: [
          IconButton(
            onPressed: () => _showAddEditMemberDialog(context, ref, null),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: loc?.translate('addMember') ?? 'Add Member',
          ),
        ],
      ),
      body: SafeArea(
        child: members.isEmpty
            ? Center(
                child: Text(
                  loc?.translate('noMembers') ??
                      'No family profiles added yet.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isSelected = selectedId == member.id;
                  final activeMedsCount = medicines
                      .where((m) => m.familyMemberId == member.id && m.isActive)
                      .length;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(appStateProvider.notifier)
                            .selectFamilyMember(member.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected profile: ${member.name}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: member.avatarColor,
                                  child: Text(
                                    member.avatarInitials,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              member.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Active',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${member.relationship} • ${member.calculatedAge} yrs ${member.birthYear != null ? "(Born ${member.birthYear})" : ""}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    member.bloodGroup.isEmpty ||
                                            member.bloodGroup == 'Not Set'
                                        ? 'O+'
                                        : member.bloodGroup,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 20,
                                  ),
                                  onSelected: (val) {
                                    if (val == 'select') {
                                      ref
                                          .read(appStateProvider.notifier)
                                          .selectFamilyMember(member.id);
                                    } else if (val == 'edit') {
                                      _showAddEditMemberDialog(
                                        context,
                                        ref,
                                        member,
                                      );
                                    } else if (val == 'delete') {
                                      _showDeleteConfirmationDialog(
                                        context,
                                        ref,
                                        member,
                                        activeMedsCount,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'select',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isSelected
                                                ? 'Active Profile'
                                                : 'Select Profile',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Profile'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.error,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete Profile',
                                            style: TextStyle(
                                              color: AppColors.error,
                                            ),
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
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.medication_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${loc?.translate('activeMedicinesCount') ?? "Active Meds"}: $activeMedsCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.phone_rounded,
                                        size: 14,
                                        color: AppColors.textSecondaryLight,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          member.emergencyContact.isEmpty
                                              ? 'N/A'
                                              : member.emergencyContact,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (member.medicalNotes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${member.medicalNotes}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddEditMemberDialog(
    BuildContext context,
    WidgetRef ref,
    FamilyMember? member,
  ) {
    final loc = AppLocalizations.of(context);
    final isEditing = member != null;

    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final relationCtrl = TextEditingController(
      text: member?.relationship ?? 'Self',
    );
    final ageCtrl = TextEditingController(
      text: (member?.calculatedAge ?? 30).toString(),
    );
    final birthYearCtrl = TextEditingController(
      text: member?.birthYear != null ? member!.birthYear.toString() : '',
    );
    final bloodCtrl = TextEditingController(text: member?.bloodGroup ?? 'O+');
    final phoneCtrl = TextEditingController(
      text: member?.emergencyContact ?? '',
    );
    final notesCtrl = TextEditingController(text: member?.medicalNotes ?? '');

    int selectedColorValue = member?.avatarColorValue ?? 0xFF087F79;
    final colorOptions = [
      0xFF087F79, // Teal
      0xFF1E40AF, // Blue
      0xFF9D174D, // Maroon
      0xFF047857, // Emerald
      0xFFD97706, // Amber
      0xFF7C3AED, // Purple
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing
                ? 'Edit Family Profile'
                : (loc?.translate('addMember') ?? 'Add Family Member'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: loc?.translate('memberName') ?? 'Member Name *',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value:
                      [
                        'Self',
                        'Father',
                        'Mother',
                        'Spouse',
                        'Son',
                        'Daughter',
                        'Sibling',
                        'Grandparent',
                        'Other',
                      ].contains(relationCtrl.text)
                      ? relationCtrl.text
                      : 'Other',
                  decoration: InputDecoration(
                    labelText: loc?.translate('relationship') ?? 'Relationship',
                    prefixIcon: const Icon(Icons.family_restroom_rounded),
                  ),
                  items:
                      [
                            'Self',
                            'Father',
                            'Mother',
                            'Spouse',
                            'Son',
                            'Daughter',
                            'Sibling',
                            'Grandparent',
                            'Other',
                          ]
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) relationCtrl.text = val;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc?.translate('age') ?? 'Age',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: birthYearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Birth Year',
                          hintText: 'e.g. 1993',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bloodCtrl,
                        decoration: InputDecoration(
                          labelText:
                              loc?.translate('bloodGroup') ?? 'Blood Group',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText:
                              loc?.translate('emergencyContact') ??
                              'Emergency Phone',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Avatar Color',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: colorOptions.map((c) {
                    final isSel = selectedColorValue == c;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColorValue = c;
                        });
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(c),
                        child: isSel
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Medical Notes (Encrypted)',
                    hintText: 'e.g. Allergies, conditions',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc?.translate('cancel') ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final initials = nameCtrl.text.trim().length >= 2
                    ? nameCtrl.text.trim().substring(0, 2).toUpperCase()
                    : nameCtrl.text.trim().substring(0, 1).toUpperCase();

                final birthYr = int.tryParse(birthYearCtrl.text.trim());
                final ageVal = int.tryParse(ageCtrl.text.trim()) ?? 30;

                final updatedMember = FamilyMember(
                  id: member?.id ?? '',
                  name: nameCtrl.text.trim(),
                  relationship: relationCtrl.text.trim(),
                  relationshipBn: 'পরিবার',
                  age: ageVal,
                  birthYear: birthYr,
                  bloodGroup: bloodCtrl.text.trim().isEmpty
                      ? 'O+'
                      : bloodCtrl.text.trim(),
                  avatarInitials: initials,
                  avatarColorValue: selectedColorValue,
                  emergencyContact: phoneCtrl.text.trim(),
                  medicalNotes: notesCtrl.text.trim(),
                );

                ref
                    .read(appStateProvider.notifier)
                    .addFamilyMember(updatedMember);
                Navigator.pop(dialogCtx);
              },
              child: Text(
                isEditing
                    ? 'Update Profile'
                    : (loc?.translate('saveMember') ?? 'Save Member'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    int activeMedsCount,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete ${member.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${member.name}\'s profile?'),
            if (activeMedsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This member has $activeMedsCount active medicines. Deleting this profile will remove its associated local records.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(appStateProvider.notifier)
                  .profileRepo
                  .deleteProfile(member.id);
              ref.read(appStateProvider.notifier).loadFromDatabase();
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Delete Profile',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
