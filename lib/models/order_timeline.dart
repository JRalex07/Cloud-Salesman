import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTimeline {
  final String timelineId;
  final String status;
  final String message;
  final String updatedBy;
  final DateTime timestamp;

  OrderTimeline({
    required this.timelineId,
    required this.status,
    required this.message,
    required this.updatedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'timelineId': timelineId,
      'status': status,
      'message': message,
      'updatedBy': updatedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      timelineId: json['timelineId'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      updatedBy: json['updatedBy'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

