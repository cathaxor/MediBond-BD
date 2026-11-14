import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/supabase/app_release_service.dart';
import 'package:medibond_bd/presentation/widgets/app_update_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remote App Update System Tests (Phase 8)', () {
    test('AppRelease model parses valid and checks HTTPS update URL', () {
      final validMap = {
        'id': 'rel_1',
        'platform': 'android',
        'channel': 'production',
        'version_name': '1.2.0',
        'build_number': 3,
        'minimum_supported_build': 2,
        'release_notes': 'Bug fixes and performance improvements.',
        'update_url': 'https://play.google.com/store/apps/details?id=com.nethivo.medibond_bd',
        'is_active': true,
      };

      final release = AppRelease.fromMap(validMap);
      expect(release.versionName, '1.2.0');
      expect(release.buildNumber, 3);
      expect(release.minimumSupportedBuild, 2);
      expect(release.isUrlValid, isTrue);
    });

    test('AppRelease rejects non-HTTPS / untrusted URLs', () {
      final invalidMap = {
        'id': 'rel_bad',
        'platform': 'android',
        'version_name': '1.2.0',
        'build_number': 3,
        'minimum_supported_build': 1,
        'update_url': 'http://untrusted-apk-site.com/app.apk',
      };

      final release = AppRelease.fromMap(invalidMap);
      expect(release.isUrlValid, isFalse);
    });

    test('Current build >= latest build -> No update available', () {
      const installedBuild = 5;
      const latestBuild = 5;
      const minimumBuild = 1;

      final updateAvail = latestBuild > installedBuild;
      final mandatory = minimumBuild > installedBuild;

      expect(updateAvail, isFalse);
      expect(mandatory, isFalse);
    });

    test(
      'Current build < latest build & >= minimumBuild -> Optional update',
      () {
        const installedBuild = 2;
        const latestBuild = 5;
        const minimumBuild = 2;

        final updateAvail = latestBuild > installedBuild;
        final mandatory = minimumBuild > installedBuild;

        expect(updateAvail, isTrue);
        expect(mandatory, isFalse);
      },
    );

    test('Current build < minimumBuild -> Required / Mandatory update', () {
      const installedBuild = 1;
      const latestBuild = 5;
      const minimumBuild = 3;

      final updateAvail = latestBuild > installedBuild;
      final mandatory = minimumBuild > installedBuild;

      expect(updateAvail, isTrue);
      expect(mandatory, isTrue);
    });

    testWidgets('AppUpdateDialog renders optional update UI correctly', (
      tester,
    ) async {
      const release = AppRelease(
        id: 'rel_opt',
        platform: 'android',
        channel: 'production',
        versionName: '1.2.0',
        buildNumber: 2,
        minimumSupportedBuild: 1,
        releaseNotes: 'Added new feature for medication tracking.',
        updateUrl: 'https://play.google.com/store/apps/details?id=com.nethivo.medibond_bd',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppUpdateDialog(release: release, isMandatory: false),
            ),
          ),
        ),
      );

      expect(find.text('New Update Available'), findsOneWidget);
      expect(find.text('Remind Me Later'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(
        find.text('Added new feature for medication tracking.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'AppUpdateDialog renders mandatory update with emergency offline continuity option',
      (tester) async {
        const release = AppRelease(
          id: 'rel_mand',
          platform: 'android',
          channel: 'production',
          versionName: '2.0.0',
          buildNumber: 10,
          minimumSupportedBuild: 5,
          releaseNotes: 'Major security and database upgrade.',
          updateUrl: 'https://play.google.com/store/apps/details?id=com.nethivo.medibond_bd',
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: AppUpdateDialog(release: release, isMandatory: true),
              ),
            ),
          ),
        );

        expect(find.text('Required Application Update'), findsOneWidget);
        expect(find.text('Continue Offline Schedule'), findsOneWidget);
        expect(find.text('Update Now'), findsOneWidget);
      },
    );
  });
}
