import 'dart:convert';
import 'package:calendar_app/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/category.dart';
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

        return events;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e, st) {
      print('🔥 Erreur lors du fetch/cache: $e');
      print(st);
      // Mode offline : retourne le cache local
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

  static Future<List<Category>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/categories'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final cats = data.map((e) => Category.fromJson(e)).toList();
        // Synchronisation locale
        await EventDatabase.clearCategories();
        for (final cat in cats) {
          await EventDatabase.insertCategory(cat);
        }
        return cats;
      } else {
        throw Exception('Erreur lors du chargement des catégories');
      }
    } catch (e) {
      // Si l'API échoue, on retourne le cache local
      return await EventDatabase.getCategories();
    }
  }

  static Future<Category> createCategory(String name, String color) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.post(
      Uri.parse('$apiBaseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'color': color}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la création de la catégorie');
    }
  }

  static Future<void> deleteCategory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final response = await http.delete(
      Uri.parse('$apiBaseUrl/categories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression de la catégorie');
    }
  }

  static Future<List<Event>> fetchEventsForDay(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final dateStr = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/events/day?date=$dateStr'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final events = data.map((e) => Event.fromJson(e)).toList();
        await EventDatabase.clearEvents();
        for (final event in events) {
          await EventDatabase.insertEvent(event);
        }
        return events;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      return await EventDatabase.getEvents();
    }
  }

  static Future<List<Event>> fetchEventsForWeek(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final dateStr = date.toIso8601String().substring(0, 10);
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/events/week?date=$dateStr'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final events = data.map((e) => Event.fromJson(e)).toList();
        await EventDatabase.clearEvents();
        for (final event in events) {
          await EventDatabase.insertEvent(event);
        }
        return events;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      return await EventDatabase.getEvents();
    }
  }

  static Future<List<Event>> fetchEventsForMonth(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final dateStr = date.toIso8601String().substring(0, 10);
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/events/month?date=$dateStr'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final events = data.map((e) => Event.fromJson(e)).toList();
        await EventDatabase.clearEvents();
        for (final event in events) {
          await EventDatabase.insertEvent(event);
        }
        return events;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      return await EventDatabase.getEvents();
    }
  }
}
