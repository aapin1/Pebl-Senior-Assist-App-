import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_updated_gradle/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';

/// Service responsible for managing local notifications
/// Routine comment: Handles initialization and scheduling for medicine reminders
class NotificationService {
  // Singleton pattern to ensure a single plugin instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false; // Track if plugin has been initialized

  /// Initialize the notification plugin and request permissions if needed
  Future<void> initialize() async {
    if (_initialized) {
      // Routine comment: Avoid re-initializing if already done
      return;
    }

    // Define initialization settings for iOS and Android
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Routine comment: Initialize timezone data for zoned scheduling
    tzdata.initializeTimeZones();

    try {
      // Routine comment: Set local timezone based on device setting
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // If timezone lookup fails, default to UTC to avoid crashes
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Request iOS permissions explicitly
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  /// Generate a unique notification ID for a medicine and reminder index
  int _notificationIdFor(String medicineId, int index) {
    // Routine comment: Use hashCode plus index and ensure non-negative
    final base = medicineId.hashCode & 0x7fffffff; // force positive
    return base + index;
  }

  /// Clear all existing notifications for this app
  Future<void> cancelAll() async {
    await initialize();
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Schedule daily notifications for a single medicine
  /// Routine comment: Cancels existing notifications for this medicine ID first
  Future<void> scheduleMedicineReminders(Medicine medicine) async {
    await initialize();

    // Cancel any existing notifications for this medicine
    await _cancelMedicineReminders(medicine.id, medicine.timesToTake.length);

    // If reminders are disabled or no times are stored, do not schedule
    if (!medicine.remindersEnabled || medicine.timesToTake.isEmpty) {
      return;
    }

    // Set up common notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medicine_reminders_channel',
      'Medicine Reminders',
      channelDescription: 'Reminders to take your medicines at the right time',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Loop through each stored time (HH:mm) and schedule a daily notification
    for (var i = 0; i < medicine.timesToTake.length; i++) {
      final value = medicine.timesToTake[i];
      final parts = value.split(':');

      if (parts.length != 2) {
        continue; // Skip invalid time values
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) {
        continue;
      }

      final id = _notificationIdFor(medicine.id, i);

      final title = 'Time to take ${medicine.name}';
      final body = medicine.dosage.isNotEmpty
          ? 'Dose: ${medicine.dosage}'
          : 'Check your medicine instructions.';

      // Routine comment: Build the next occurrence of this time in the local timezone
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        // If time today has already passed, schedule for tomorrow
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Routine comment: Schedule a daily notification at this local time
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Cancel notifications for a specific medicine
  Future<void> _cancelMedicineReminders(String medicineId, int count) async {
    await initialize();

    for (var i = 0; i < count; i++) {
      final id = _notificationIdFor(medicineId, i);
      await _flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  /// Reschedule reminders for all medicines in the list
  /// Routine comment: Clears all previous reminders and recreates them
  Future<void> rescheduleAll(List<Medicine> medicines) async {
    await initialize();

    // Clear existing notifications to avoid duplicates
    await cancelAll();

    for (final medicine in medicines) {
      await scheduleMedicineReminders(medicine);
    }
  }
}
