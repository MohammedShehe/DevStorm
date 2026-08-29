import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/dose_log_model.dart';

/// Schedules and shows local phone notifications for medicine doses.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'meditrack_dose_reminders',
    'Medicine Reminders',
    description: 'Alerts when it is time to take your medicine',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Android 13+ notification permission + channel
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.createNotificationChannel(_channel);
      // Exact alarms help for precise dose times (Android 12+)
      await android?.requestExactAlarmsPermission();
    }

    if (!kIsWeb && Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  int _idForDose(String doseId) {
    // Stable positive 32-bit-ish id from string
    return doseId.hashCode & 0x7fffffff;
  }

  Future<void> showInstant({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleDose(DoseLog dose) async {
    if (!_initialized) await init();
    if (dose.status != DoseStatus.upcoming) return;

    final when = dose.scheduledTime;
    if (when.isBefore(DateTime.now())) return;

    final id = _idForDose(dose.id);
    final tzWhen = tz.TZDateTime.from(when, tz.local);

    final title = 'Time to take ${dose.medicineName}';
    final body = '${dose.dosage} · Scheduled for ${_formatTime(when)}';

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.reminder,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body, contentTitle: title),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: dose.id,
      );
    } catch (e) {
      // Fallback without exact alarm if permission denied
      debugPrint('Exact schedule failed, retrying inexact: $e');
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzWhen,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: dose.id,
        );
      } catch (e2) {
        debugPrint('Schedule notification failed: $e2');
      }
    }
  }

  Future<void> cancelDose(String doseId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_idForDose(doseId));
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  /// Reschedule upcoming doses (today + near future). Caps to avoid OS limits.
  Future<void> syncDoseReminders(List<DoseLog> doses) async {
    if (!_initialized) await init();
    final upcoming = doses
        .where((d) => d.status == DoseStatus.upcoming && d.scheduledTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // Cancel existing then reschedule next batch (Android limits pending notifications)
    await cancelAll();
    final batch = upcoming.take(50);
    for (final d in batch) {
      await scheduleDose(d);
    }
  }

  String _formatTime(DateTime t) {
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}
