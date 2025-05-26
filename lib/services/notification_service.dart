import 'package:calendar_app/main.dart';
import 'package:calendar_app/models/event.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Événements',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      'Événement à venir',
      tz.TZDateTime.from(
        scheduledTime.subtract(const Duration(minutes: 10)),
        tz.local,
      ),
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showTestNotification() async {
  final androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test',
    importance: Importance.high,
    priority: Priority.high,
  );

  final windowsDetails = WindowsNotificationDetails();

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    windows: windowsDetails,
  );

  await _notifications.show(
    0, 
    'Test Notification',
    'Ceci est un test depuis Flutter 🎉',
    notificationDetails,
  );
}

static Future<void> syncPendingNotifications(List<Event> events) async {
  final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  final pendingIds = pending.map((n) => n.id).toSet();

  final now = DateTime.now();

  for (final event in events) {
    final reminder = event.reminderMinutes;
    if (reminder == null) continue;

    final scheduled = event.startTime.subtract(Duration(minutes: reminder));
    if (scheduled.isBefore(now)) continue;

    final notifId = _generateId(event.id);

    if (!pendingIds.contains(notifId)) {
      await scheduleNotification(
        id: notifId,
        title: 'Rappel : ${event.title}',
        scheduledTime: scheduled,
      );
      print('🔔 Notification reprogrammée pour ${event.title}');
    }
  }
}

/// Convertit un ID UUID en entier stable pour FlutterLocalNotifications
static int _generateId(String uuid) {
  return uuid.hashCode & 0x7FFFFFFF; // entier positif
}


}
