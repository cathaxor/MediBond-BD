import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/security/security_controller.dart';
import 'package:medibond_bd/presentation/widgets/privacy_shield_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Lifecycle & Security Shield Regression Tests (Phase 9)', () {
    testWidgets(
      'Normal button interaction and active screen rendering does NOT show Security Active screen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PrivacyShieldOverlay(
                child: Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Active UI Button'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Active UI Button'), findsOneWidget);
        expect(find.text('MediBond BD Security Active'), findsNothing);
      },
    );

    testWidgets(
      'Temporary AppLifecycleState.inactive (file picker, permission popup, soft keyboard) does NOT show Security Active screen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: PrivacyShieldOverlay(
                child: Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Interactive Screen'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate temporary focus loss (inactive state sent during file picker or permission prompt)
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();

        expect(find.text('Interactive Screen'), findsOneWidget);
        expect(find.text('MediBond BD Security Active'), findsNothing);
      },
    );

    testWidgets(
      'App Lock overlay displays only when security policy explicitly locks the app',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Enable App Lock
        container
            .read(securityControllerProvider.notifier)
            .setAppLockEnabled(true);
        container.read(securityControllerProvider.notifier).lockImmediately();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: PrivacyShieldOverlay(
                child: Scaffold(body: Text('Protected Main View')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('MediBond BD Locked'), findsOneWidget);

        // Unlock
        await container
            .read(securityControllerProvider.notifier)
            .unlockApp(pin: '1234');
        await tester.pumpAndSettle();

        expect(find.text('Protected Main View'), findsOneWidget);
        expect(find.text('MediBond BD Locked'), findsNothing);
      },
    );
  });
}
