import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AlarmPermissionHelper {
  static Future<void> promptExactAlarmPermission(BuildContext context) async {
    if (!Platform.isAndroid) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission requise"),
        content: const Text(
          "Pour que les rappels fonctionnent, autorisez l'application à planifier des alarmes exactes.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              const intent = AndroidIntent(
                action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
              );
              intent.launch();
              Navigator.pop(context);
            },
            child: const Text("Ouvrir les paramètres"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }
}
