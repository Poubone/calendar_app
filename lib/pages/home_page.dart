import 'package:calendar_app/pages/event_detail_page.dart';
import 'package:calendar_app/pages/event_form_page.dart';
import 'package:calendar_app/services/event_service.dart';
import 'package:calendar_app/services/notification_service.dart';
import 'package:calendar_app/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login_page.dart';
import '../models/event.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    final events = await EventService.fetchAndCacheEvents();
    print("Loaded ${events.length} events");
    setState(() {
      _events = events;
      _isLoading = false;
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events.where((e) {
      return e.startTime.year == day.year &&
          e.startTime.month == day.month &&
          e.startTime.day == day.day;
    }).toList();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              final pending =
                  await NotificationService.getPendingNotifications();

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Notifications programmées'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (pending.isEmpty)
                            const Text('Aucune notification programmée'),
                          ...pending.map(
                            (n) => ListTile(
                              title: Text(n.title ?? 'Sans titre'),
                              subtitle: Text(n.payload ?? 'ID ${n.id}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: 'Supprimer cette notification',
                                onPressed: () async {
                                  await NotificationService.cancelNotification(
                                    n.id,
                                  );

                                  final refreshed =
                                      await NotificationService.getPendingNotifications();

                                  if (context.mounted) {
                                    Navigator.pop(
                                      context,
                                    ); // Ferme l'ancien dialogue

                                    // Rouvre un nouveau dialogue avec la liste mise à jour
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Notifications programmées',
                                          ),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                if (refreshed.isEmpty)
                                                  const Text(
                                                    'Aucune notification programmée',
                                                  ),
                                                ...refreshed.map(
                                                  (notif) => ListTile(
                                                    title: Text(
                                                      notif.title ??
                                                          'Sans titre',
                                                    ),
                                                    subtitle: Text(
                                                      notif.payload ??
                                                          'ID ${notif.id}',
                                                    ),
                                                    trailing: IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                      tooltip:
                                                          'Supprimer cette notification',
                                                      onPressed: () async {
                                                        await NotificationService.cancelNotification(
                                                          notif.id,
                                                        );
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Fermer'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          const Divider(),
                          TextButton.icon(
                            icon: const Icon(Icons.notification_important),
                            label: const Text('Tester une notification'),
                            onPressed: () {
                              NotificationService.showTestNotification();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedEvents.isEmpty
                ? const Center(child: Text('Aucun événement'))
                : AnimatedList(
                    key: GlobalKey<AnimatedListState>(),
                    initialItemCount: selectedEvents.length,
                    itemBuilder: (context, index, animation) {
                      final event = selectedEvents[index];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(event: event),
                            ),
                          );

                          // Si on revient avec "delete", on recharge les events
                          if (result == 'delete') {
                            await EventService.deleteEvent(event.id);
                            await NotificationService.cancelNotification(
                              NotificationService.generateId(event.id),
                            );

                            setState(() {
                              _isLoading = true;
                            });

                            _loadEvents();
                          }
                        },
                        child: Hero(
                          tag: 'event-${event.id}',
                          child: EventCard(event: event, animation: animation),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
