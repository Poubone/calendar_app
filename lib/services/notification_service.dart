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
    required int reminderMinutes,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'event_channel',
      'Événements',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final localScheduled = scheduledTime.toLocal();
    final finalScheduledTime = localScheduled.subtract(
      Duration(minutes: reminderMinutes),
    );

    print('🕒 Notification prévue pour (locale) : $finalScheduledTime');

    final tzDate = tz.TZDateTime.local(
      finalScheduledTime.year,
      finalScheduledTime.month,
      finalScheduledTime.day,
      finalScheduledTime.hour,
      finalScheduledTime.minute,
    );

    final now = tz.TZDateTime.now(tz.local);
    await _notifications.zonedSchedule(
      999999,
      'Test Immédiat',
      'Juste pour test',
      now.add(const Duration(minutes: 1)),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      'Événement à venir',
      tzDate,
      notificationDetails,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'eventId:$id|time:${tzDate.toIso8601String()}',
    );
    print('✅ Notification programmée pour $title à $tzDate');
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
      'Ceci est un test depuis le bouton Flutter 🎉',
      notificationDetails,
    );
  }

  static Future<void> syncPendingNotifications(List<Event> events) async {
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    final pendingIds = pending.map((n) => n.id).toSet();

    final now = DateTime.now();

    for (final event in events) {
      final reminder = event.reminderMinutes;
      if (reminder == null) continue;

      final scheduled = event.startTime.subtract(Duration(minutes: reminder));
      if (scheduled.isBefore(now)) continue;
      final notifId = generateId(event.id);
      if (!pendingIds.contains(notifId)) {
        await scheduleNotification(
          id: notifId,
          title: 'Rappel : ${event.title}',
          scheduledTime: event.startTime,
          reminderMinutes: reminder,
        );

        print('🔔 Notification reprogrammée pour ${event.title}');
      }
    }
  }

  static int generateId(String eventId) => eventId.hashCode;

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  static Future<void> cancelNotification(int id) async {
  await flutterLocalNotificationsPlugin.cancel(id);
  print('❌ Notification $id annulée');
}


  static Future<void> clearPastNotifications() async {
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    for (final n in pending) {
      final match = RegExp(r'time:(.*?)$').firstMatch(n.payload ?? '');
      final scheduledStr = match?.group(1);
      final scheduledTime = DateTime.tryParse(scheduledStr ?? '');

      if (scheduledTime != null && scheduledTime.isBefore(DateTime.now())) {
        await flutterLocalNotificationsPlugin.cancel(n.id);
        print('🗑️ Notification expirée supprimée (ID: ${n.id})');
      }
    }
  }
}
