import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/models/notification.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesman = ref.watch(salesmanProfileProvider).valueOrNull;

    if (salesman == null) {
      return const Scaffold(body: Center(child: Text('Session missing.')));
    }

    final firestore = ref.watch(firestoreProvider);
    final notificationsStream = firestore
        .collection('salesmen')
        .doc(salesman.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 54, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('All caught up! No active alerts.', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              final data = doc.data();
              // Capture dynamic notification records
              final fNotification = AppNotification.fromJson({
                'notificationId': doc.id,
                ...data,
              });

              return Card(
                color: fNotification.read ? Colors.white : Colors.blue[50]?.withOpacity(0.5),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(fNotification.type).withOpacity(0.1),
                    child: Icon(_getTypeIcon(fNotification.type), color: _getTypeColor(fNotification.type), size: 20),
                  ),
                  title: Text(
                    fNotification.title,
                    style: TextStyle(fontWeight: fNotification.read ? FontWeight.normal : FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(fNotification.body, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      Text(
                        fNotification.createdAt.toLocal().toString().split('.')[0],
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  trailing: !fNotification.read
                      ? IconButton(
                          icon: const Icon(Icons.mark_email_read_outlined, size: 18, color: Colors.blue),
                          tooltip: 'Mark as read',
                          onPressed: () async {
                            await firestore
                                .collection('salesmen')
                                .doc(salesman.uid)
                                .collection('notifications')
                                .doc(doc.id)
                                .update({'read': true});
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'VisitUpdate':
        return Colors.blue;
      case 'OrderDispatch':
        return Colors.green;
      case 'SystemAlert':
        return Colors.red;
      case 'Announcement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'VisitUpdate':
        return Icons.directions_walk;
      case 'OrderDispatch':
        return Icons.local_shipping;
      case 'SystemAlert':
        return Icons.warning_amber;
      case 'Announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}

