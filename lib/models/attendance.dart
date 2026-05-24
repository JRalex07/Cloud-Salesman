import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String attendanceId;
  final DateTime? startDutyTime;
  final DateTime? endDutyTime;
  final int duration; // in minutes
  final String date;  // YYYY-MM-DD format
  final String status; // 'Present', 'Absent', 'HalfDay'
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;

  Attendance({
    required this.attendanceId,
    this.startDutyTime,
    this.endDutyTime,
    required this.duration,
    required this.date,
    required this.status,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'attendanceId': attendanceId,
      'startDutyTime': startDutyTime != null ? Timestamp.fromDate(startDutyTime!) : null,
      'endDutyTime': endDutyTime != null ? Timestamp.fromDate(endDutyTime!) : null,
      'duration': duration,
      'date': date,
      'status': status,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: json['attendanceId'] ?? '',
      startDutyTime: (json['startDutyTime'] as Timestamp?)?.toDate(),
      endDutyTime: (json['endDutyTime'] as Timestamp?)?.toDate(),
      duration: json['duration'] ?? 0,
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      startLatitude: (json['startLatitude'] as num?)?.toDouble() ?? 0.0,
      startLongitude: (json['startLongitude'] as num?)?.toDouble() ?? 0.0,
      endLatitude: (json['endLatitude'] as num?)?.toDouble() ?? 0.0,
      endLongitude: (json['endLongitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Attendance copyWith({
    String? attendanceId,
    DateTime? startDutyTime,
    DateTime? endDutyTime,
    int? duration,
    String? date,
    String? status,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
  }) {
    return Attendance(
      attendanceId: attendanceId ?? this.attendanceId,
      startDutyTime: startDutyTime ?? this.startDutyTime,
      endDutyTime: endDutyTime ?? this.endDutyTime,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      status: status ?? this.status,
      startLatitude: startLatitude ?? this.startLatitude,
      startLongitude: startLongitude ?? this.startLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
    );
  }
}

