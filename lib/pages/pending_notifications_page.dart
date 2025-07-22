import 'package:flutter/material.dart';
import 'package:calendar_app/services/notification_api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PendingNotificationsPage extends StatefulWidget {
  @override
  State<PendingNotificationsPage> createState() => _PendingNotificationsPageState();
}

class _PendingNotificationsPageState extends State<PendingNotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final notifs = await NotificationApiService.getUnreadNotifications();
    // Filtre : ne garde que celles qui n'ont pas encore été push
    setState(() {
      _notifications = notifs.where((n) => n['pushedAt'] == null).toList();
      _loading = false;
    });
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications à venir', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('Aucune notification à venir', style: GoogleFonts.poppins()))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) {
                    final notif = _notifications[i];
                    final dateStr = _formatDate(notif['triggerAt']);
                    return ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: Text(notif['title'] ?? '(Sans titre)', style: GoogleFonts.poppins()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${notif['id']}', style: GoogleFonts.poppins(fontSize: 13)),
                          if (notif['body'] != null && notif['body'].toString().isNotEmpty)
                            Text(notif['body'], style: GoogleFonts.poppins(fontSize: 13)),
                          if (dateStr != null)
                            Text('Prévue le : $dateStr', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
} 