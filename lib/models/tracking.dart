import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingPoints {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final DateTime timestamp;

  TrackingPoints({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory TrackingPoints.fromJson(Map<String, dynamic> json) {
    return TrackingPoints(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

