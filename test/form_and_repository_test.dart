import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/localization/app_localizations.dart';
import 'package:medibond_bd/core/security/secure_encryption_service.dart';
import 'package:medibond_bd/data/database/app_database.dart';
import 'package:medibond_bd/data/models/family_member.dart';
import 'package:medibond_bd/data/models/medicine.dart';
import 'package:medibond_bd/data/providers/database_providers.dart';
import 'package:medibond_bd/data/repositories/medicine_repository.dart';
import 'package:medibond_bd/data/repositories/profile_repository.dart';
import 'package:medibond_bd/presentation/screens/medicines/add_edit_medicine_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SecureEncryptionService encryptionService;
  late ProfileRepository profileRepo;
  late MedicineRepository medicineRepo;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    encryptionService = SecureEncryptionService();
    profileRepo = DriftProfileRepository(db, encryptionService);
    medicineRepo = DriftMedicineRepository(db, encryptionService);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3 Medicine Form & Repository Tests', () {
    test(
      'MedicineRepository pause, resume, archive and restore operations',
      () async {
        final profileId = const Uuid().v4();
        await profileRepo.saveProfile(
          FamilyMember(
            id: profileId,
            name: 'Tanvir',
            relationship: 'Self',
            relationshipBn: 'আমি',
            age: 32,
            bloodGroup: 'O+',
            avatarInitials: 'TA',
            avatarColorValue: 0xFF087F79,
            emergencyContact: '+880 1700 000000',
          ),
        );

        final medId = const Uuid().v4();
        final med = Medicine(
          id: medId,
          name: 'Napa Extra',
          strength: '500 mg',
          form: MedicineForm.tablet,
          dosage: '1 Tablet',
          instructions: MealInstruction.afterFood,
          timesPerDay: 2,
          scheduledTimes: const [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 20, minute: 0),
          ],
          familyMemberId: profileId,
          stockCount: 20,
          startDate: DateTime.now(),
          weekdays: const [1, 2, 3, 4, 5],
        );

        await medicineRepo.saveMedicine(med);

        var fetched = await medicineRepo.getMedicineById(medId);
        expect(fetched, isNotNull);
        expect(fetched!.isPaused, isFalse);
        expect(fetched.isActive, isTrue);
        expect(fetched.strength, '500 mg');

        await medicineRepo.togglePauseMedicine(medId, true);
        fetched = await medicineRepo.getMedicineById(medId);
        expect(fetched!.isPaused, isTrue);

        await medicineRepo.toggleArchiveMedicine(medId, false);
        fetched = await medicineRepo.getMedicineById(medId);
        expect(fetched!.isActive, isFalse);
      },
    );

    testWidgets('AddEditMedicineScreen validates required medicine name', (
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
            home: AddEditMedicineScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final saveBtn = find.byType(ElevatedButton);
      await tester.dragUntilVisible(
        saveBtn,
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(saveBtn, findsOneWidget);

      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Medicine name is required'), findsOneWidget);

      await testDb.close();
    });
  });
}
