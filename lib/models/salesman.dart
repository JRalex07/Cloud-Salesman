import 'package:cloud_firestore/cloud_firestore.dart';

class Salesman {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role;
  final String assignedRouteId;
  final String assignedArea;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLogin;
  final String fcmToken;

  Salesman({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.assignedRouteId,
    required this.assignedArea,
    required this.isActive,
    required this.createdAt,
    required this.lastLogin,
    required this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'assignedRouteId': assignedRouteId,
      'assignedArea': assignedArea,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'fcmToken': fcmToken,
    };
  }

  factory Salesman.fromJson(Map<String, dynamic> json) {
    return Salesman(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      role: json['role'] ?? '',
      assignedRouteId: json['assignedRouteId'] ?? '',
      assignedArea: json['assignedArea'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (json['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: json['fcmToken'] ?? '',
    );
  }

  Salesman copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    String? assignedRouteId,
    String? assignedArea,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? fcmToken,
  }) {
    return Salesman(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      assignedRouteId: assignedRouteId ?? this.assignedRouteId,
      assignedArea: assignedArea ?? this.assignedArea,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

