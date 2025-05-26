import 'dart:convert';
import 'package:calendar_app/constants.dart';
import 'package:calendar_app/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import 'event_database.dart';

class EventService {
  static Future<List<Event>> fetchAndCacheEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');

      final response = await http.get(
        Uri.parse('$apiBaseUrl/events'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final events = data.map((e) => Event.fromJson(e)).toList();

        // On sauvegarde dans SQLite
        await EventDatabase.clearEvents();
        for (final event in events) {
          await EventDatabase.insertEvent(event);
        }
        await NotificationService.syncPendingNotifications(events);

        return events;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e, st) {
      print('🔥 Erreur lors du fetch/cache: $e');
      print(st);
      return await EventDatabase.getEvents();
    }
  }

  static Future<void> deleteEvent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    print('🔍 Suppression de l\'événement ID: ${id}');

    final response = await http.delete(
      Uri.parse('$apiBaseUrl/events/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      await EventDatabase.clearEvents(); 
    } else {
      throw Exception('Erreur de suppression : ${response.statusCode}');
    }
  }
}
