import 'dart:io';
import 'package:flutter/foundation.dart';

/// URL de base de l'API selon la plateforme (web, android, desktop...)
String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else if (Platform.isAndroid) {
    return 'http://192.168.1.4:3000'; // Android emulator vers hôte
  } else {
    return 'http://localhost:3000'; // Desktop ou iOS simulator
  }
}
