import 'dart:io';
import 'package:flutter/foundation.dart';

/// URL de base de l'API selon la plateforme (web, android, desktop...)
String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080';
  } else if (Platform.isAndroid) {
    return 'http://192.168.1.4:8080'; // Android emulator vers hôte
  } else {
    return 'http://localhost:8080'; // Desktop ou iOS simulator
  }
}
