import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pages/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit(); // équivalent de SQLlite pour les plateformes desktop
    databaseFactory = databaseFactoryFfi; 
  }


  const WindowsInitializationSettings windowsSettings =
      WindowsInitializationSettings(
        appName: 'Calendar App',
        appUserModelId: 'com.example.calendar_app',
        guid: "77997b95-e361-424d-8b96-f8ab74f46c2c",
      );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    windows: windowsSettings,
  );

  tz.initializeTimeZones();
   // 🔐 Demande la permission si nécessaire
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }


  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const CalendarApp());
}

class CalendarApp extends StatelessWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const SplashScreen(),
    );
  }
}
