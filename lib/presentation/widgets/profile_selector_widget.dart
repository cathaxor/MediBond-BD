import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../state/app_state_provider.dart';

class ProfileSelectorWidget extends ConsumerWidget {
  const ProfileSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final selectedId = appState.selectedFamilyMemberId;
    final members = appState.members;
    final loc = AppLocalizations.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: members.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedId == 'all';
            return ChoiceChip(
              avatar: Icon(
                Icons.people_alt_rounded,
                size: 18,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
              label: Text(
                loc?.translate('allProfiles') ?? 'All Members',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              onSelected: (_) {
                ref.read(appStateProvider.notifier).selectFamilyMember('all');
              },
            );
          }

          final member = members[index - 1];
          final isSelected = selectedId == member.id;

          return ChoiceChip(
            avatar: CircleAvatar(
              backgroundColor: isSelected
                  ? Colors.white.withAlpha(200)
                  : member.avatarColor,
              radius: 12,
              child: Text(
                member.avatarInitials,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
            label: Text(
              member.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            onSelected: (_) {
              ref.read(appStateProvider.notifier).selectFamilyMember(member.id);
            },
          );
        },
      ),
    );
  }
}
