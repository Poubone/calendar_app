import 'dart:convert';
import 'package:calendar_app/helper/alarm_permission_helper.dart';
import 'package:calendar_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'home_page.dart';

class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _reminderMinutes;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Merci de remplir les champs requis');
      return;
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      _showError('Veuillez sélectionner une date et des horaires');
      return;
    }

    final start = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final end = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (start.isAfter(end)) {
      _showError('L’heure de fin doit être après celle de début');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.post(
      Uri.parse('$apiBaseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': _titleController.text,
        'description': _descController.text,
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'isAllDay': false,
        'category': null,
        'recurrenceRule': null,
        'reminderMinutes': _reminderMinutes,
      }),
    );

    if (response.statusCode == 201) {
      await AlarmPermissionHelper.promptExactAlarmPermission(context);

      if (_reminderMinutes != null) {
        if (start.isAfter(DateTime.now().add(const Duration(seconds: 3)))) {
          await NotificationService.scheduleNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: _titleController.text,
            scheduledTime: start, 
            reminderMinutes: _reminderMinutes!, 
          );
        } else {
          print('⏩ Notification non programmée (événement trop proche)');
        }
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      _showError('Erreur lors de la création (${response.statusCode})');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel événement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate != null
                      ? 'Date : ${_selectedDate!.toLocal().toString().split(' ')[0]}'
                      : 'Choisir une date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                title: Text(
                  _startTime != null
                      ? 'Heure de début : ${_startTime!.format(context)}'
                      : 'Choisir heure de début',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                title: Text(
                  _endTime != null
                      ? 'Heure de fin : ${_endTime!.format(context)}'
                      : 'Choisir heure de fin',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isStart: false),
              ),
              DropdownButtonFormField<int>(
                value: _reminderMinutes,
                decoration: const InputDecoration(
                  labelText: 'Rappel',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text("Aucun rappel")),
                  DropdownMenuItem(value: 5, child: Text("5 minutes avant")),
                  DropdownMenuItem(value: 10, child: Text("10 minutes avant")),
                  DropdownMenuItem(value: 30, child: Text("30 minutes avant")),
                ],
                onChanged: (value) {
                  setState(() {
                    _reminderMinutes = value;
                  });
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
