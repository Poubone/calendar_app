import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart'; // en haut du fichier
import 'event_form_page.dart';
import '../services/event_service.dart';

class EventDetailPage extends StatelessWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'event-${event.id}',
      child: Scaffold(
        appBar: AppBar(
          title: Text('Détail'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventFormPage(event: event)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer'),
                    content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await EventService.deleteEvent(event.id);
                  if (context.mounted) Navigator.pop(context, 'delete');
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(seconds: 1),
                    child: Text(
                      (event.description?.isNotEmpty ?? false)
                          ? event.description!
                          : 'Pas de description',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.schedule),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat.Hm().format(event.startTime.toLocal())} - '
                        '${DateFormat.Hm().format(event.endTime.toLocal())}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (event.reminderMinutes != null)
                    Row(
                      children: [
                        const Icon(Icons.alarm),
                        const SizedBox(width: 8),
                        Text('${event.reminderMinutes} min avant'),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
