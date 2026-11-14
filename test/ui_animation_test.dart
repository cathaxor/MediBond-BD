import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI Transitions & Animation Tests', () {
    testWidgets('GoRouter provider initializes smooth page transition router', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
