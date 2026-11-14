import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/medication_log.dart';
import '../../data/models/medicine.dart';

typedef NotificationActionCallback = Future<void> Function(
  String logId,
  MedicationLogStatus status,
  String actionKey,
);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  NotificationActionCallback? _onActionCallback;
  bool _hideNameOnLockScreen = false;

  void setPrivacyOption(bool hideName) {
    _hideNameOnLockScreen = hideName;
  }

  Future<void> initialize({
    NotificationActionCallback? onActionCallback,
  }) async {
    if (_isInitialized) return;
    _onActionCallback = onActionCallback;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return false;
  }

  void _handleNotificationResponse(NotificationResponse response) async {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload == null || payload.isEmpty) return;

    if (actionId == 'take_action') {
      if (_onActionCallback != null) {
        await _onActionCallback!(payload, MedicationLogStatus.taken, 'take');
      }
    } else if (actionId == 'skip_action') {
      if (_onActionCallback != null) {
        await _onActionCallback!(payload, MedicationLogStatus.skipped, 'skip');
      }
    } else if (actionId == 'snooze_action') {
      await snoozeReminder(
        logId: payload,
        title: _hideNameOnLockScreen ? 'Medicine Reminder' : 'Snoozed Medicine',
        body: 'Snoozed dose reminder (10 minutes)',
        snoozeMinutes: 10,
      );
      if (_onActionCallback != null) {
        await _onActionCallback!(
          payload,
          MedicationLogStatus.pending,
          'snooze',
        );
      }
    }
  }

  /// Calculates next notification time based on schedule, weekdays, and current time
  DateTime calculateNextOccurrence({
    required TimeOfDay time,
    required List<int> weekdays,
    required DateTime fromDate,
  }) {
    var candidate = DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day,
      time.hour,
      time.minute,
    );

    if (candidate.isBefore(fromDate)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    final activeWeekdays = weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : weekdays;
    while (!activeWeekdays.contains(candidate.weekday)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  /// Schedules local alarm notification for a medicine dose
  Future<int> scheduleDoseReminder({
    required String logId,
    required String medicineName,
    required String dosage,
    required String memberName,
    required DateTime scheduledDateTime,
    required int notificationId,
  }) async {
    if (!_isInitialized) await initialize();

    final title = _hideNameOnLockScreen
        ? 'Medicine Reminder'
        : 'Medicine Reminder: $medicineName';
    final body = _hideNameOnLockScreen
        ? 'Time to take your scheduled medicine ($memberName)'
        : '$dosage • Scheduled for $memberName';

    final androidDetails = AndroidNotificationDetails(
      'medibond_reminders_channel',
      'Medicine Reminders',
      channelDescription: 'Timely reminders for scheduled medicine doses',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      actions: const [
        AndroidNotificationAction(
          'take_action',
          'Take',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'skip_action',
          'Skip',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze_action',
          'Snooze 10m',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      final tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: logId,
      );
    } catch (_) {
      // Inexact fallback if exact scheduling is unavailable on device
      try {
        final tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: logId,
        );
      } catch (_) {}
    }

    return notificationId;
  }

  /// Snoozes reminder without modifying original dose time in schedule
  Future<void> snoozeReminder({
    required String logId,
    required String title,
    required String body,
    int snoozeMinutes = 10,
  }) async {
    if (!_isInitialized) await initialize();

    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    final notificationId = logId.hashCode.abs() + 999;

    final androidDetails = AndroidNotificationDetails(
      'medibond_reminders_channel',
      'Medicine Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      final tzSnooze = tz.TZDateTime.from(snoozeTime, tz.local);
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzSnooze,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: logId,
      );
    } catch (_) {}
  }

  /// Cancels scheduled notification by ID
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _plugin.cancel(notificationId);
    } catch (_) {}
  }

  /// Cancels all active scheduled notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Idempotently reconciles and restores future alarms after device reboot or app update
  Future<void> reconcileAndRestoreAlarms(List<Medicine> medicines) async {
    if (!_isInitialized) await initialize();
    await cancelAllNotifications();

    final now = DateTime.now();
    for (var med in medicines) {
      if (!med.isActive || med.isPaused) continue;

      for (var time in med.scheduledTimes) {
        final nextOccurrence = calculateNextOccurrence(
          time: time,
          weekdays: med.weekdays,
          fromDate: now,
        );

        final notificationId = '${med.id}_${time.hour}_${time.minute}'.hashCode
            .abs();
        await scheduleDoseReminder(
          logId: 'reboot_${med.id}_${time.hour}',
          medicineName: med.name,
          dosage: med.dosage,
          memberName: 'Family Member',
          scheduledDateTime: nextOccurrence,
          notificationId: notificationId,
        );
      }
    }
  }
}
