import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../state/app_state_provider.dart';

class MyProfileScreen extends ConsumerWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final profile = appState.primaryProfile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 64,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              const Text('No primary profile setup yet.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Create Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.translate('myProfile') ?? 'My Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar & Name Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: profile.avatarColor,
                        child: Text(
                          profile.avatarInitials,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${profile.relationship} Profile',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personal Information
              _buildSectionCard(
                context: context,
                title: 'Personal Information',
                icon: Icons.person_outline_rounded,
                onAddTap: () => context.push('/edit-profile'),
                items: [
                  _DetailItem(
                    label: 'Age / DOB',
                    value: profile.dateOfBirth != null
                        ? '${profile.calculatedAge} Yrs (${DateFormat('dd MMM yyyy').format(profile.dateOfBirth!)})'
                        : (profile.age > 0
                              ? '${profile.age} Years'
                              : 'Not Set'),
                  ),
                  _DetailItem(label: 'Gender', value: profile.displayGender),
                ],
              ),
              const SizedBox(height: 16),

              // Health Information
              _buildSectionCard(
                context: context,
                title: 'Health Information',
                icon: Icons.health_and_safety_outlined,
                onAddTap: () => context.push('/edit-profile'),
                items: [
                  _DetailItem(
                    label: 'Blood Group',
                    value: profile.displayBloodGroup,
                    valueColor:
                        profile.bloodGroup != 'Not Set' &&
                            profile.bloodGroup.isNotEmpty
                        ? AppColors.error
                        : null,
                  ),
                  _DetailItem(label: 'Height', value: profile.displayHeight),
                  _DetailItem(label: 'Weight', value: profile.displayWeight),
                  _DetailItem(
                    label: 'Known Allergies',
                    value: profile.displayAllergies,
                  ),
                  _DetailItem(
                    label: 'Medical Notes',
                    value: profile.displayMedicalNotes,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Emergency Contact
              _buildSectionCard(
                context: context,
                title: 'Emergency Contact',
                icon: Icons.phone_outlined,
                onAddTap: () => context.push('/edit-profile'),
                items: [
                  _DetailItem(
                    label: 'Contact',
                    value: profile.displayEmergencyContact,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onAddTap,
    required List<_DetailItem> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.map((item) {
              final isNotSet = item.value == 'Not Set';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isNotSet
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: isNotSet
                                ? AppColors.textSecondaryLight
                                : (item.valueColor ??
                                      Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color),
                          ),
                        ),
                        if (isNotSet) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onAddTap,
                            child: const Text(
                              '+ Add',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final Color? valueColor;

  _DetailItem({required this.label, required this.value, this.valueColor});
}
