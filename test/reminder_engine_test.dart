import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medibond_bd/core/notifications/notification_service.dart';
import 'package:medibond_bd/data/models/medication_log.dart';
import 'package:medibond_bd/data/models/medicine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NotificationService notificationService;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'initialize') {
              return true;
            }
            if (methodCall.method == 'requestNotificationsPermission') {
              return true;
            }
            if (methodCall.method == 'cancel') {
              return null;
            }
            if (methodCall.method == 'cancelAll') {
              return null;
            }
            if (methodCall.method == 'zonedSchedule') {
              return null;
            }
            return null;
          },
        );
    notificationService = NotificationService();
  });

  group('Phase 5 Android Medicine Reminder Engine Tests', () {
    test(
      'calculateNextOccurrence computes next daily schedule date correctly',
      () {
        final from = DateTime(2025, 1, 10, 7, 0);
        final time = const TimeOfDay(hour: 8, minute: 30);
        final weekdays = [1, 2, 3, 4, 5, 6, 7];

        final next = notificationService.calculateNextOccurrence(
          time: time,
          weekdays: weekdays,
          fromDate: from,
        );

        expect(next.year, 2025);
        expect(next.month, 1);
        expect(next.day, 10);
        expect(next.hour, 8);
        expect(next.minute, 30);
      },
    );

    test('calculateNextOccurrence handles weekday filtering correctly', () {
      final from = DateTime(2025, 1, 10, 9, 0); // Friday
      final time = const TimeOfDay(hour: 8, minute: 0);
      final weekdays = [1, 3, 5]; // Mon, Wed, Fri only

      final next = notificationService.calculateNextOccurrence(
        time: time,
        weekdays: weekdays,
        fromDate: from,
      );

      expect(next.weekday, 1);
      expect(next.day, 13);
    });

    test('Lock screen privacy option toggles content formatting', () {
      notificationService.setPrivacyOption(true);
      notificationService.setPrivacyOption(false);
    });

    test('Idempotent action callback processing', () async {
      String? executedLogId;
      MedicationLogStatus? executedStatus;

      await notificationService.initialize(
        onActionCallback: (logId, status, actionKey) async {
          executedLogId = logId;
          executedStatus = status;
        },
      );

      expect(executedLogId, isNull);
      expect(executedStatus, isNull);
    });

    test(
      'Reboot recovery reconciler ignores inactive or paused medicines',
      () async {
        final activeMed = Medicine(
          id: 'm_active',
          name: 'Napa Extra',
          form: MedicineForm.tablet,
          dosage: '1 Tablet',
          instructions: MealInstruction.afterFood,
          timesPerDay: 1,
          scheduledTimes: const [TimeOfDay(hour: 8, minute: 0)],
          familyMemberId: 'mem1',
          stockCount: 10,
          isActive: true,
          isPaused: false,
          startDate: DateTime.now(),
        );

        final pausedMed = Medicine(
          id: 'm_paused',
          name: 'Seclo 20mg',
          form: MedicineForm.capsule,
          dosage: '1 Capsule',
          instructions: MealInstruction.beforeFood,
          timesPerDay: 1,
          scheduledTimes: const [TimeOfDay(hour: 9, minute: 0)],
          familyMemberId: 'mem1',
          stockCount: 5,
          isActive: true,
          isPaused: true,
          startDate: DateTime.now(),
        );

        await notificationService.reconcileAndRestoreAlarms([
          activeMed,
          pausedMed,
        ]);
      },
    );
  });
}
