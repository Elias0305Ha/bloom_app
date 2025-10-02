import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Timezone setup for scheduled notifications
    tz.initializeTimeZones();
    final String localName = tz.local.name;
    tz.setLocalLocation(tz.getLocation(localName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    // Android 13+ runtime permission for notifications
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static NotificationDetails _defaultDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'bloom_general',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    return const NotificationDetails(android: androidDetails);
  }

  static Future<void> showImmediate({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(0, title, body, _defaultDetails());
  }

  static Future<void> scheduleInSeconds({
    required String title,
    required String body,
    int seconds = 5,
  }) async {
    await initialize();
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    try {
      await _plugin.zonedSchedule(
        1,
        title,
        body,
        when,
        _defaultDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: null,
      );
    } catch (e) {
      // Fallback to immediate notification if scheduling fails
      await _plugin.show(1, title, body, _defaultDetails());
    }
  }

  static Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  static Future<void> scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _defaultDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: null,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback without match if exact alarms not permitted
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _defaultDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: null,
      );
    }
  }
}


