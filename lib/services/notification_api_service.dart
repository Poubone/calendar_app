import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class NotificationApiService {
  static Future<List<dynamic>> getAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des notifications');
    }
  }

  static Future<List<dynamic>> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.get(
      Uri.parse('$apiBaseUrl/notifications/unread'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des notifications non lues');
    }
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.put(
      Uri.parse('$apiBaseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors du passage en lu');
    }
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.put(
      Uri.parse('$apiBaseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors du passage en lu de toutes les notifications');
    }
  }

  static Future<void> createNotification({
    required String title,
    required String body,
    String? eventId,
    DateTime? triggerAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final Map<String, dynamic> data = {
      'title': title,
      'body': body,
    };
    if (eventId != null) data['eventId'] = eventId;
    if (triggerAt != null) data['triggerAt'] = triggerAt.toIso8601String();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Erreur lors de la création de la notification');
    }
  }
} 