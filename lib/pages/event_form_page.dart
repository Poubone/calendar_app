import 'dart:convert';
import 'package:calendar_app/helper/alarm_permission_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'home_page.dart';
import '../models/category.dart';
import '../services/event_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/event.dart';
import 'package:collection/collection.dart';
import 'package:calendar_app/services/notification_api_service.dart';

class EventFormPage extends StatefulWidget {
  final Event? event;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  const EventFormPage({super.key, this.event, this.initialDate, this.initialStartTime, this.initialEndTime});

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
  bool _customReminder = false;
  final _customReminderController = TextEditingController();
  String _customReminderUnit = 'min'; // 'min', 'h', 'j'
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _loadingCategories = true;
  Color _defaultCategoryColor = const Color(0xFFB5EAEA);

  bool get isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEdit) {
      final e = widget.event!;
      _titleController.text = e.title;
      _descController.text = e.description ?? '';
      _selectedDate = e.startTime.toLocal();
      _startTime = TimeOfDay(hour: e.startTime.toLocal().hour, minute: e.startTime.toLocal().minute);
      _endTime = TimeOfDay(hour: e.endTime.toLocal().hour, minute: e.endTime.toLocal().minute);
      _reminderMinutes = e.reminderMinutes;
    } else {
      final now = DateTime.now();
      _selectedDate = widget.initialDate ?? now;
      _startTime = widget.initialStartTime ?? TimeOfDay(hour: now.hour, minute: now.minute);
      final end = now.add(const Duration(hours: 1));
      _endTime = widget.initialEndTime ?? TimeOfDay(hour: end.hour, minute: end.minute);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await EventService.fetchCategories();
      setState(() {
        _categories = cats;
        _loadingCategories = false;
        if (isEdit && widget.event!.category != null) {
          _selectedCategory = cats.firstWhereOrNull((c) => c.id == widget.event!.category!.id);
        }
      });
    } catch (e) {
      setState(() {
        _loadingCategories = false;
      });
      _showError('Erreur lors du chargement des catégories');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Merci de remplir les champs requis');
      return;
    }

    if (_selectedDate == null || _startTime == null || _endTime == null) {
      _showError('Veuillez sélectionner une date et des horaires');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Veuillez choisir une catégorie');
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

    if (_customReminder && _reminderMinutes == null) {
      _showError('Veuillez saisir le nombre de minutes pour le rappel personnalisé.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final startUtc = start.toUtc();
    final endUtc = end.toUtc();

    final url = isEdit
        ? Uri.parse('$apiBaseUrl/events/${widget.event!.id}')
        : Uri.parse('$apiBaseUrl/events');
    final method = isEdit ? 'PUT' : 'POST';
    final body = jsonEncode({
        'title': _titleController.text,
        'description': _descController.text,
        'startTime': startUtc.toIso8601String(),
        'endTime': endUtc.toIso8601String(),
        'isAllDay': false,
      'categoryId': _selectedCategory!.id,
        'recurrenceRule': null,
        'reminderMinutes': _reminderMinutes,
    });
    final response = await http.Request(method, url)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = body;
    final streamed = await response.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      await AlarmPermissionHelper.promptExactAlarmPermission(context);
      final eventId = isEdit ? widget.event!.id : jsonDecode(resp.body)['eventId'];

      // Création des notifications via l'API
      final now = DateTime.now();
      // 1. Notification de rappel (optionnelle)
      if (_reminderMinutes != null && _reminderMinutes! > 0) {
        final triggerAt = start.subtract(Duration(minutes: _reminderMinutes!));
        if (triggerAt.isAfter(now)) {
          await NotificationApiService.createNotification(
            title: 'Rappel : ${_titleController.text}',
            body: 'L\'événement "${_titleController.text}" commence à ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
            eventId: eventId,
            triggerAt: triggerAt,
          );
        }
      }
      // 2. Notification de début d'événement
      if (start.isAfter(now)) {
        await NotificationApiService.createNotification(
          title: _titleController.text,
          body: 'L\'événement commence maintenant',
          eventId: eventId,
          triggerAt: start,
        );
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      _showError('Erreur lors de la création (${resp.statusCode})');
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
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24)),
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
    final pastel = Theme.of(context).brightness == Brightness.dark
        ? Color(0xFF232526)
        : Color(0xFFF6F8FF);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier un événement' : 'Nouvel événement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: pastel,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                      Text('Créer un événement',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Titre',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                        style: GoogleFonts.poppins(),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.notes),
                        ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
                      _loadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<Category>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: 'Catégorie',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.category),
                                    ),
                                    items: _categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat.name, style: GoogleFonts.poppins()),
                                            ))
                                        .toList(),
                                    onChanged: (cat) {
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                    },
                                    validator: (cat) => cat == null ? 'Champ requis' : null,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  tooltip: 'Créer une catégorie',
                                  onPressed: () async {
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) {
                                String newCat = '';
                                Color color = _defaultCategoryColor;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('Nouvelle catégorie'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            autofocus: true,
                                            decoration: const InputDecoration(labelText: 'Nom'),
                                            onChanged: (v) => newCat = v,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Text('Couleur :'),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () async {
                                                  final picked = await showDialog<Color>(
                                                    context: context,
                                                    builder: (context) {
                                                      Color temp = color;
                                                      return AlertDialog(
                                                        title: const Text('Choisir une couleur'),
                                                        content: SingleChildScrollView(
                                                          child: BlockPicker(
                                                            pickerColor: temp,
                                                            onColorChanged: (c) => temp = c,
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('Annuler'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(context, temp),
                                                            child: const Text('Valider'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                  if (picked != null) setState(() => color = picked);
                                                },
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: Colors.black26),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, {'name': newCat, 'color': color}),
                                          child: const Text('Créer'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (result != null && (result['name'] as String).trim().isNotEmpty) {
                              try {
                                final colorHex = '#${(result['color'] as Color).value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                                final cat = await EventService.createCategory((result['name'] as String).trim(), colorHex);
                                setState(() {
                                  _categories.add(cat);
                                  _selectedCategory = cat;
                                });
                              } catch (e) {
                                _showError('Erreur lors de la création de la catégorie');
                              }
                            }
                          },
                        ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Colors.white.withOpacity(0.7),
                title: Text(
                  _selectedDate != null
                      ? 'Date : ${_selectedDate!.toLocal().toString().split(' ')[0]}'
                      : 'Choisir une date',
                                style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Colors.white.withOpacity(0.7),
                title: Text(
                  _startTime != null
                      ? 'Heure de début : ${_startTime!.format(context)}'
                      : 'Choisir heure de début',
                                style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isStart: true),
              ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Colors.white.withOpacity(0.7),
                title: Text(
                  _endTime != null
                      ? 'Heure de fin : ${_endTime!.format(context)}'
                      : 'Choisir heure de fin',
                                style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickTime(isStart: false),
              ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _customReminder ? null : _reminderMinutes,
                decoration: InputDecoration(
                  labelText: 'Rappel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.alarm),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Aucun')),
                  const DropdownMenuItem(value: 5, child: Text('5 min avant')),
                  const DropdownMenuItem(value: 15, child: Text('15 min avant')),
                  const DropdownMenuItem(value: 30, child: Text('30 min avant')),
                  const DropdownMenuItem(value: 60, child: Text('1h avant')),
                  const DropdownMenuItem(value: 1440, child: Text('1 jour avant')),
                  const DropdownMenuItem(value: -1, child: Text('Personnalisé...')),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val == -1) {
                      _customReminder = true;
                      _reminderMinutes = null;
                    } else {
                      _customReminder = false;
                      _reminderMinutes = val;
                    }
                  });
                },
              ),
              if (_customReminder)
                const SizedBox(height: 16),
              if (_customReminder)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customReminderController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rappel',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          setState(() {
                            if (parsed != null) {
                              if (_customReminderUnit == 'min') {
                                _reminderMinutes = parsed;
                              } else if (_customReminderUnit == 'h') {
                                _reminderMinutes = parsed * 60;
                              } else if (_customReminderUnit == 'j') {
                                _reminderMinutes = parsed * 1440;
                              }
                            } else {
                              _reminderMinutes = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _customReminderUnit,
                      items: const [
                        DropdownMenuItem(value: 'min', child: Text('min')),
                        DropdownMenuItem(value: 'h', child: Text('heures')),
                        DropdownMenuItem(value: 'j', child: Text('jours')),
                      ],
                      onChanged: (unit) {
                        setState(() {
                          _customReminderUnit = unit!;
                          final parsed = int.tryParse(_customReminderController.text);
                          if (parsed != null) {
                            if (_customReminderUnit == 'min') {
                              _reminderMinutes = parsed;
                            } else if (_customReminderUnit == 'h') {
                              _reminderMinutes = parsed * 60;
                            } else if (_customReminderUnit == 'j') {
                              _reminderMinutes = parsed * 1440;
                            }
                          } else {
                            _reminderMinutes = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                          label: Text(isEdit ? 'Modifier' : 'Enregistrer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
