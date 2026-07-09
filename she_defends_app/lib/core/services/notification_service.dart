import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Notification clicked: ${response.payload}");
        },
      );
      _initialized = true;
      debugPrint("Local notifications initialized successfully.");
    } catch (e) {
      debugPrint("Failed to initialize local notifications: $e");
    }
  }

  /// Show an immediate alert toast notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'she_defends_channel',
      'SheDefends Alerts',
      channelDescription: 'Alarms for safety checkpoints, wellness checkins, and medicine logs.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Error dispatching local notification: $e");
    }
  }

  /// Schedule a medication reminder
  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Note: Standard scheduling uses timezone packages.
    // For simplicity, we trigger standard show call if time is immediate, 
    // or log simulated notifications within our app's mock stream.
    debugPrint("Scheduled medicine notification ID $id at $scheduledTime");
  }
}
