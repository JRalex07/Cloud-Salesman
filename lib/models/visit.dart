import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String visitId;
  final String shopId;
  final String shopName;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double checkOutLatitude;
  final double checkOutLongitude;
  final double distanceFromShop;
  final String notes;
  final String status; // 'CheckedIn', 'Completed', 'Cancelled'
  final DateTime createdAt;

  Visit({
    required this.visitId,
    required this.shopId,
    required this.shopName,
    this.checkInTime,
    this.checkOutTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.checkOutLatitude,
    required this.checkOutLongitude,
    required this.distanceFromShop,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'visitId': visitId,
      'shopId': shopId,
      'shopName': shopName,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'distanceFromShop': distanceFromShop,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      visitId: json['visitId'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      checkInTime: (json['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (json['checkOutTime'] as Timestamp?)?.toDate(),
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble() ?? 0.0,
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble() ?? 0.0,
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceFromShop: (json['distanceFromShop'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Visit copyWith({
    String? visitId,
    String? shopId,
    String? shopName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    double? distanceFromShop,
    String? notes,
    String? status,
    DateTime? createdAt,
  }) {
    return Visit(
      visitId: visitId ?? this.visitId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      distanceFromShop: distanceFromShop ?? this.distanceFromShop,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

