import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String notificationId;
  final String title;
  final String body;
  final String type; // 'VisitUpdate', 'OrderDispatch', 'SystemAlert', 'Announcement'
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'type': type,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'SystemAlert',
      read: json['read'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AppNotification copyWith({
    String? notificationId,
    String? title,
    String? body,
    String? type,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

