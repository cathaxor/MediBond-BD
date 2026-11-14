import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/localization/app_localizations.dart';
import 'package:medibond_bd/core/notifications/notification_service.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/providers/database_providers.dart';
import 'package:medibond_bd/data/repositories/dose_event_repository.dart';
import 'package:medibond_bd/data/repositories/medicine_repository.dart';
import 'package:medibond_bd/data/repositories/prescription_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';
import 'package:medibond_bd/presentation/screens/home/home_dashboard_screen.dart';
import 'package:medibond_bd/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:medibond_bd/state/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late ProfileRepository profileRepo;
  late MedicineRepository medicineRepo;
  late DoseEventRepository doseEventRepo;
  late PrescriptionRepository prescriptionRepo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    encryptionService = SecureEncryptionService();
    profileRepo = DriftProfileRepository(db, encryptionService);
    medicineRepo = DriftMedicineRepository(db, encryptionService);
    doseEventRepo = DriftDoseEventRepository(db);
    prescriptionRepo = DriftPrescriptionRepository(db, encryptionService);
  });

  tearDown(() async {
    await db.close();
  });

  group('First Launch, Onboarding, Profile & Data Safety Tests', () {
    test(
      'Fresh install has no demo data in production initialization',
      () async {
        final notifier = AppStateNotifier(
          profileRepo: profileRepo,
          medicineRepo: medicineRepo,
          doseEventRepo: doseEventRepo,
          prescriptionRepo: prescriptionRepo,
        );

        await notifier.initDatabase();

        expect(notifier.state.members.isEmpty, isTrue);
        expect(notifier.state.medicines.isEmpty, isTrue);
        expect(notifier.state.logs.isEmpty, isTrue);
        expect(notifier.state.prescriptions.isEmpty, isTrue);
        expect(notifier.state.hasPrimaryProfile, isFalse);
      },
    );

    test(
      'Primary profile creation, app restart persistence, and migration',
      () async {
        final notifier = AppStateNotifier(
          profileRepo: profileRepo,
          medicineRepo: medicineRepo,
          doseEventRepo: doseEventRepo,
          prescriptionRepo: prescriptionRepo,
        );

        await notifier.initDatabase();
        expect(notifier.state.hasPrimaryProfile, isFalse);

        final primary = const FamilyMember(
          id: 'primary_self',
          name: 'Tanvir Ahmed',
          relationship: 'Self',
          relationshipBn: 'আমি',
          age: 32,
          birthYear: 1993,
          gender: 'Male',
          bloodGroup: 'O+',
          avatarInitials: 'TA',
          avatarColorValue: 0xFF087F79,
          emergencyContact: '+880 1700 000000',
        );

        await notifier.addFamilyMember(primary);

        expect(notifier.state.hasPrimaryProfile, isTrue);
        expect(notifier.state.primaryUserName, 'Tanvir Ahmed');

        // Simulate App Restart (re-reading from SQLite database)
        final restartedNotifier = AppStateNotifier(
          profileRepo: profileRepo,
          medicineRepo: medicineRepo,
          doseEventRepo: doseEventRepo,
          prescriptionRepo: prescriptionRepo,
        );

        await restartedNotifier.initDatabase();

        expect(restartedNotifier.state.hasPrimaryProfile, isTrue);
        expect(restartedNotifier.state.primaryUserName, 'Tanvir Ahmed');
      },
    );

    test('Profile editing updates persistent state', () async {
      final primary = const FamilyMember(
        id: 'primary_self',
        name: 'Tanvir Ahmed',
        relationship: 'Self',
        relationshipBn: 'আমি',
        age: 32,
        gender: 'Male',
        bloodGroup: 'O+',
        avatarInitials: 'TA',
        avatarColorValue: 0xFF087F79,
        emergencyContact: '+880 1700 000000',
      );

      await profileRepo.saveProfile(primary);

      final updated = primary.copyWith(name: 'Tanvir A. Khan', age: 33);
      await profileRepo.saveProfile(updated);

      final fetched = await profileRepo.getProfileById('primary_self');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Tanvir A. Khan');
      expect(fetched.age, 33);
    });

    test('Notification permission request handler operates safely', () async {
      final service = NotificationService();
      final granted = await service.requestPermissions();
      expect(granted, isA<bool>());
    });

    testWidgets('Fresh install onboarding screen renders setup form', (
      WidgetTester tester,
    ) async {
      final testDb = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(testDb)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);

      await testDb.close();
    });

    testWidgets('Empty home dashboard renders no medicines state', (
      WidgetTester tester,
    ) async {
      final testDb = AppDatabase(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(testDb)],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No medicines added yet'), findsAtLeast(1));
      expect(find.text('Add Your First Medicine'), findsOneWidget);

      await testDb.close();
    });
  });
}
