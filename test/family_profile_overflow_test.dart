import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/providers/database_providers.dart';
import 'package:medibond_bd/presentation/screens/family/family_profiles_screen.dart';
import 'package:medibond_bd/state/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FamilyProfilesScreen renders long English and Bangla names without overflow',
    (tester) async {
      // Set small screen constraints (320x600)
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;

      const longMember1 = FamilyMember(
        id: 'member_long_1',
        name: 'Dr. Mohammad Tanvir Ahmed Chowdhury Siddiqui',
        relationship: 'Self',
        relationshipBn: 'আমি',
        age: 35,
        bloodGroup: 'AB+',
        avatarInitials: 'MT',
        avatarColorValue: 0xFF087F79,
        emergencyContact: '+880 1700 000000',
        medicalNotes: 'Very long medical notes with special conditions',
      );

      const longMember2 = FamilyMember(
        id: 'member_long_2',
        name: 'ডাঃ মোহাম্মদ তানভীর আহমেদ চৌধুরী সিদ্দিকী',
        relationship: 'Father',
        relationshipBn: 'বাবা',
        age: 68,
        bloodGroup: 'O-',
        avatarInitials: 'MT',
        avatarColorValue: 0xFF1E40AF,
        emergencyContact: '+880 1800 111222',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appStateProvider.overrideWith((ref) {
              final notifier = AppStateNotifier(
                profileRepo: ref.watch(profileRepositoryProvider),
                medicineRepo: ref.watch(medicineRepositoryProvider),
                doseEventRepo: ref.watch(doseEventRepositoryProvider),
                prescriptionRepo: ref.watch(prescriptionRepositoryProvider),
              );
              notifier.state = AppStateData(
                members: const [longMember1, longMember2],
                medicines: const [],
                logs: const [],
                prescriptions: const [],
                selectedFamilyMemberId: 'member_long_1',
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(home: FamilyProfilesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FamilyProfilesScreen), findsOneWidget);
      expect(find.textContaining('Dr. Mohammad Tanvir'), findsOneWidget);
      expect(find.textContaining('AB+'), findsOneWidget);
      expect(find.textContaining('O-'), findsOneWidget);

      // Verify no overflow errors were thrown
      expect(tester.takeException(), isNull);

      // Reset view
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );
}
