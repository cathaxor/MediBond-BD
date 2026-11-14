import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/theme/theme_provider.dart';
import 'package:medibond_bd/presentation/screens/settings/developer_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Developer Info & Dynamic Theme Tests', () {
    testWidgets(
      'DeveloperInfoScreen renders developer name and social profile cards',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: DeveloperInfoScreen())),
        );

        await tester.pumpAndSettle();

        expect(find.text('Abdur Rahaman Abdulla'), findsOneWidget);
        expect(find.text('Lead Engineer & Founder • CatHaxor'), findsOneWidget);
        expect(find.text('A Nethivo Product'), findsOneWidget);

        final githubBtn = find.text('Visit GitHub Profile (@cathaxor)');
        await tester.dragUntilVisible(
          githubBtn,
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(githubBtn, findsOneWidget);

        final instaBtn = find.text('Follow on Instagram (@abdulla_trzz)');
        await tester.dragUntilVisible(
          instaBtn,
          find.byType(ListView),
          const Offset(0, -200),
        );
        expect(instaBtn, findsOneWidget);
      },
    );

    testWidgets(
      'ThemeSettingsNotifier updates accent color and persists state',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(themeSettingsProvider.notifier);

        expect(
          container.read(themeSettingsProvider).accentColor,
          AppAccentColor.teal,
        );

        await notifier.setAccentColor(AppAccentColor.blue);

        expect(
          container.read(themeSettingsProvider).accentColor,
          AppAccentColor.blue,
        );
      },
    );
  });
}
