import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Animation<double> animation;

  const EventCard({super.key, required this.event, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.event, color: Colors.blue),
            title: Text(event.title),
            subtitle: Text(
              '${DateFormat.Hm().format(event.startTime.toLocal())} - '
              '${DateFormat.Hm().format(event.endTime.toLocal())}',
            ),
          ),
        ),
      ),
    );
  }
}
