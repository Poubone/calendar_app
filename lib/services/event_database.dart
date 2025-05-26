import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:calendar_app/models/event.dart';

class EventDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calendar.db');




    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        isAllDay INTEGER,
        category TEXT,
        recurrenceRule TEXT,
        reminderMinutes INTEGER
      )
    ''');
  }

static Future<void> insertEvent(Event event) async {
  final db = await database;
  await db.insert('events', event.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
}


  static Future<List<Event>> getEvents() async {
    final db = await database;
    final maps = await db.query('events', orderBy: 'startTime ASC');

    return maps.map((e) => Event.fromJson(e)).toList();
  }

  static Future<void> clearEvents() async {
    final db = await database;
    await db.delete('events');
  }
}
