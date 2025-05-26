import 'package:flutter/material.dart';
import '../models/event.dart';

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
              icon: const Icon(Icons.delete),
              onPressed: () {
                Navigator.pop(context, 'delete');
              },
            ),
          ],
        ),
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
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
                    '${event.startTime.hour.toString().padLeft(2, '0')}h${event.startTime.minute.toString().padLeft(2, '0')}'
                    ' - ${event.endTime.hour.toString().padLeft(2, '0')}h${event.endTime.minute.toString().padLeft(2, '0')}',
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
    );
  }
}
