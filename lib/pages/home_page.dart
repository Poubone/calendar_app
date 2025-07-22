import 'package:calendar_app/pages/event_detail_page.dart';
import 'package:calendar_app/pages/event_form_page.dart';
import 'package:calendar_app/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../models/event.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:collection/collection.dart';
import 'package:calendar_app/pages/category_management_page.dart';
import 'package:calendar_app/pages/pending_notifications_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final ThemeMode? themeMode;
  const HomePage({super.key, this.onToggleTheme, this.themeMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  bool _isLoading = true;
  CalendarView _calendarView = CalendarView.week;
  DateTime _calendarDisplayDate = DateTime.now();
  Key _calendarKey = UniqueKey();
  DateTime? _lastLoadedDisplayDate; // Ajout pour éviter la boucle infinie

  @override
  void initState() {
    super.initState();
    _loadEvents();
    // Rafraîchit la liste si on revient d'une suppression/modification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)?.addScopedWillPopCallback(() async {
        _loadEvents();
        return true;
      });
    });
  }

  void _loadEvents() async {
    setState(() { _isLoading = true; });
    List<Event> events;
    if (_calendarView == CalendarView.day) {
      events = await EventService.fetchEventsForDay(_selectedDay ?? _calendarDisplayDate);
    } else if (_calendarView == CalendarView.week) {
      events = await EventService.fetchEventsForWeek(_calendarDisplayDate);
    } else {
      events = await EventService.fetchEventsForMonth(_calendarDisplayDate);
    }
    setState(() {
      _events = events;
      _isLoading = false;
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Ajout de la locale française
    return Localizations.override(
      context: context,
      locale: const Locale('fr'),
      delegates: const [
        SfGlobalLocalizations.delegate,
      ],
      child: _buildScaffold(context, isDark),
    );
  }

  Widget _buildScaffold(BuildContext context, bool isDark) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark ? Colors.indigo[900] : Colors.indigo[100],
              ),
              child: Text('Menu', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Icon(Icons.category, color: Colors.blue[400]),
              title: Text('Gérer les catégories', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoryManagementPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.amber[700]),
              title: Text('Notifications prévues', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PendingNotificationsPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [

          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            tooltip: widget.themeMode == ThemeMode.dark ? 'Mode clair' : 'Mode sombre',
            onPressed: widget.onToggleTheme ?? () {},
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Précédent',
            onPressed: () {
              setState(() {
                if (_calendarView == CalendarView.month) {
                  _calendarDisplayDate = DateTime(
                    _calendarDisplayDate.year,
                    _calendarDisplayDate.month - 1,
                    1,
                  );
                } else if (_calendarView == CalendarView.week) {
                  _calendarDisplayDate = _calendarDisplayDate.subtract(const Duration(days: 7));
                } else {
                  _calendarDisplayDate = _calendarDisplayDate.subtract(const Duration(days: 1));
                }
                _calendarKey = UniqueKey();
              });
              _loadEvents();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CalendarView>(
                value: _calendarView,
                icon: const Icon(Icons.arrow_drop_down),
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                dropdownColor: Theme.of(context).cardColor,
                items: const [
                  DropdownMenuItem(
                    value: CalendarView.month,
                    child: Text('Mois'),
                  ),
                  DropdownMenuItem(
                    value: CalendarView.week,
                    child: Text('Semaine'),
                  ),
                  DropdownMenuItem(
                    value: CalendarView.day,
                    child: Text('Jour'),
                  ),
                ],
                onChanged: (view) {
                  if (view != null) {
                    setState(() {
                      _calendarView = view;
                      _calendarKey = UniqueKey();
                    });
                    _loadEvents();
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Suivant',
            onPressed: () {
              setState(() {
                if (_calendarView == CalendarView.month) {
                  _calendarDisplayDate = DateTime(
                    _calendarDisplayDate.year,
                    _calendarDisplayDate.month + 1,
                    1,
                  );
                } else if (_calendarView == CalendarView.week) {
                  _calendarDisplayDate = _calendarDisplayDate.add(const Duration(days: 7));
                } else {
                  _calendarDisplayDate = _calendarDisplayDate.add(const Duration(days: 1));
                }
                _calendarKey = UniqueKey();
              });
              _loadEvents();
            },
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SfCalendar(
                key: _calendarKey,
                view: _calendarView,
                initialDisplayDate: _calendarDisplayDate,
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeFormat: 'HH:mm',
                  timeIntervalHeight: 60, // Hauteur augmentée pour une meilleure lisibilité
                ),
                onViewChanged: (viewChangedDetails) {
                  final newDisplayDate = viewChangedDetails.visibleDates[viewChangedDetails.visibleDates.length ~/ 2];
                  if (_lastLoadedDisplayDate == null || !_isSameDay(_lastLoadedDisplayDate!, newDisplayDate)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _calendarDisplayDate = newDisplayDate;
                          _lastLoadedDisplayDate = newDisplayDate;
                        });
                        _loadEvents();
                      }
                    });
                  }
                },
                onTap: (calendarTapDetails) {
                  if (_calendarView == CalendarView.month && calendarTapDetails.date != null) {
                    // Toujours basculer en vue jour sur ce jour, même s'il y a des events
                    setState(() {
                      _selectedDay = calendarTapDetails.date!;
                      _calendarView = CalendarView.day;
                      _calendarDisplayDate = calendarTapDetails.date!;
                      _calendarKey = UniqueKey();
                    });
                    _loadEvents();
                  } else if (calendarTapDetails.appointments != null && calendarTapDetails.appointments!.isNotEmpty) {
                    // Ouvre le détail de l'événement (en vue semaine ou jour)
                    final Appointment tapped = calendarTapDetails.appointments!.first;
                    String? eventId;
                    if (tapped.notes != null && tapped.notes!.startsWith('eventId:')) {
                      eventId = tapped.notes!.substring('eventId:'.length);
                    }
                    final event = eventId != null
                        ? _events.firstWhereOrNull((e) => e.id == eventId)
                        : null;
                    if (event != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
                      ).then((result) {
                        if (result == 'delete') _loadEvents();
                      });
                    }
                  } else if (calendarTapDetails.date != null && _calendarView != CalendarView.month) {
                    // Clic sur un créneau vide en vue jour/semaine : ouvrir création d'event avec heure préremplie
                    final date = calendarTapDetails.date!;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventFormPage(
                          initialDate: date.toLocal(),
                          initialStartTime: TimeOfDay(hour: date.toLocal().hour, minute: date.toLocal().minute),
                          initialEndTime: TimeOfDay(hour: date.toLocal().add(const Duration(hours: 1)).hour, minute: date.toLocal().add(const Duration(hours: 1)).minute),
                        ),
                      ),
                    ).then((_) => _loadEvents());
                  } else if (calendarTapDetails.date != null) {
                    // Cas normal pour semaine/jour
                    setState(() {
                      _selectedDay = calendarTapDetails.date!;
                      _focusedDay = calendarTapDetails.date!;
                    });
                    _loadEvents();
                  }
                },
                dataSource: _EventDataSource(_convertEventsToAppointments(_events)),
                todayHighlightColor: Colors.indigo,
                selectionDecoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.2),
                  border: Border.all(color: Colors.indigo, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                  showAgenda: false,
                ),
                appointmentBuilder: (context, details) {
                  if (_calendarView == CalendarView.month) {
                    final appointments = details.appointments.toList();
                    // N'affiche la liste scrollable qu'une seule fois par case (pour le premier event)
                    if (appointments.isEmpty || details.appointments.first != appointments[0]) {
                      return const SizedBox.shrink();
                    }
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: appointments.length,
                      itemBuilder: (context, i) {
                        final a = appointments[i];
                        return Container(
                          height: 18.0,
                          margin: EdgeInsets.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                          decoration: BoxDecoration(
                            color: a.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              a.subject,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  // Autres vues : n'affiche que le titre, police plus grande
                  final appointment = details.appointments.first;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        decoration: BoxDecoration(
                          color: appointment.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                        child: Text(
                          appointment.subject,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15, // Agrandi en semaine/jour
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventFormPage()),
          ).then((_) => _loadEvents());
        },
        icon: const Icon(Icons.add),
        label: const Text(''),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  List<Appointment> _convertEventsToAppointments(List<Event> events) {
    return events.map((e) {
      final color = _parseCategoryColor(e.category?.color) ?? _getPastelColor(e.category?.name ?? e.title);
      // Ajoute l'id dans notes pour le matching fiable
      return Appointment(
        startTime: e.startTime.toLocal(),
        endTime: e.endTime.toLocal(),
        subject: e.title,
        notes: 'eventId:${e.id}',
        isAllDay: e.isAllDay,
        color: color,
      );
    }).toList();
  }

  Color? _parseCategoryColor(String? hex) {
    if (hex == null || !hex.startsWith('#')) return null;
    String cleaned = hex.substring(1);
    if (cleaned.length == 6) {
      // #RRGGBB
      cleaned = 'FF$cleaned';
    } else if (cleaned.length == 8) {
      // #AARRGGBB
      // ok
    } else {
      return null;
    }
    return Color(int.parse(cleaned, radix: 16));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<Appointment> source) {
    appointments = source;
  }
}

Color _getPastelColor(String label) {
  final colors = [
    const Color(0xFFB5EAEA), // bleu pastel
    const Color(0xFFFFBCBC), // rose pastel
    const Color(0xFFFFE2E2), // crème
    const Color(0xFFB28DFF), // violet pastel
    const Color(0xFFFFD6E0), // rose clair
    const Color(0xFFB5FFD9), // vert pastel
    const Color(0xFFFFF5BA), // jaune pastel
  ];
  return colors[label.hashCode % colors.length];
}

// Ajoute cette fonction utilitaire pour le format 24h français
String _formatHourFr(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
