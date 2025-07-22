import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pages/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_app/services/notification_api_service.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:calendar_app/services/api_service.dart';
import 'dart:convert';
import 'constants.dart';
import 'dart:typed_data';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await Firebase.initializeApp();
    setupFCM();
  }

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
  tz.setLocalLocation(tz.getLocation('Europe/Paris')); 

  
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }


  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const CalendarApp());
}

void setupFCM() {
  if (!(Platform.isAndroid || Platform.isIOS)) return;
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Notification reçue en foreground
    print('Notification FCM reçue:  [35m${message.notification?.title} [0m');
    final plugin = FlutterLocalNotificationsPlugin();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'event_channel',
        'Événements',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      ),
      windows: WindowsNotificationDetails(),
    );
    plugin.show(
      message.hashCode,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      details,
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification FCM cliquée');
  });

  FirebaseMessaging.instance.getToken().then((token) {
    print('FCM Token: $token');
    // Envoie ce token à ton backend pour lier l'utilisateur à son device
  });

  // Demande la permission de notifications (Android 13+)
  FirebaseMessaging.instance.requestPermission();

  // Ajout : écoute le refresh du token FCM et le renvoie à l'API
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt');
    if (jwt != null) {
      try {
        await http.patch(
          Uri.parse('$apiBaseUrl/me/fcm-token'),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fcmToken': newToken}),
        );
      } catch (e) {
        // ignore erreur réseau
      }
    }
  });
}


class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Timer? _notifTimer;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  void initState() {
    super.initState();
    _startNotificationPolling();
    if (Platform.isAndroid || Platform.isIOS) {
      setupFCM();
    }
  }

  void _startNotificationPolling() {
    if (Platform.isWindows) {
      _notifTimer?.cancel();
      // Calcule le temps jusqu'à la prochaine minute multiple de 5
      final now = DateTime.now();
      final nextMinute = (now.minute ~/ 5 + 1) * 5;
      final nextTime = DateTime(now.year, now.month, now.day, now.hour, nextMinute);
      final initialDelay = nextTime.difference(now);
      Timer(initialDelay, () {
        _runNotificationPolling();
        _notifTimer = Timer.periodic(const Duration(minutes: 5), (_) => _runNotificationPolling());
      });
    }
  }

  void _runNotificationPolling() async {
    print('[NOTIF POLLING] Vérification des notifications à ${DateTime.now()}');
    try {
      final notifs = await NotificationApiService.getUnreadNotifications();
      final now = DateTime.now();
      for (final notif in notifs) {
        final triggerAt = notif['triggerAt'] != null ? DateTime.tryParse(notif['triggerAt'])?.toLocal() : null;
        if (triggerAt != null && _isSameMinute(triggerAt, now)) {
          // Affiche la notification locale
          final plugin = FlutterLocalNotificationsPlugin();
          final details = NotificationDetails(
            windows: WindowsNotificationDetails(),
            android: AndroidNotificationDetails(
              'event_channel',
              'Événements',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
            ),
          );
          await plugin.show(
            notif['id'].hashCode,
            notif['title'] ?? 'Notification',
            notif['body'] ?? '',
            details,
          );
          // Marque comme lue
          await NotificationApiService.markAsRead(notif['id']);
        }
      }
    } catch (e) {
      // ignore erreur réseau
    }
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day && a.hour == b.hour && a.minute == b.minute;
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode');
    setState(() {
      if (mode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        SfGlobalLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}
