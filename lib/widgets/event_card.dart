import 'package:flutter/material.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:blur/blur.dart';

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
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 70,
          borderRadius: 16,
          blur: 12,
          alignment: Alignment.center,
          border: 0.7,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.18),
              Colors.blue.withOpacity(0.12),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.4),
              Colors.blue.withOpacity(0.2),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.event, color: Colors.blue),
            title: Text(
              event.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              '${DateFormat.Hm().format(event.startTime.toLocal())} - '
              '${DateFormat.Hm().format(event.endTime.toLocal())}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
