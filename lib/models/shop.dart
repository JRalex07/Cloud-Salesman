import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String shopId;
  final String shopName;
  final String shopkeeperName;
  final String phone;
  final String whatsapp;
  final String address;
  final double latitude;
  final double longitude;
  final String salesmanId;
  final String routeId;
  final String area;
  final String imageUrl;
  final String notes;
  final DateTime createdAt;
  final bool approved;
  final bool active;

  Shop({
    required this.shopId,
    required this.shopName,
    required this.shopkeeperName,
    required this.phone,
    required this.whatsapp,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.salesmanId,
    required this.routeId,
    required this.area,
    required this.imageUrl,
    required this.notes,
    required this.createdAt,
    required this.approved,
    required this.active,
  });

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'shopkeeperName': shopkeeperName,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'salesmanId': salesmanId,
      'routeId': routeId,
      'area': area,
      'imageUrl': imageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'approved': approved,
      'active': active,
    };
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      shopkeeperName: json['shopkeeperName'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      salesmanId: json['salesmanId'] ?? '',
      routeId: json['routeId'] ?? '',
      area: json['area'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approved: json['approved'] ?? false,
      active: json['active'] ?? false,
    );
  }

  Shop copyWith({
    String? shopId,
    String? shopName,
    String? shopkeeperName,
    String? phone,
    String? whatsapp,
    String? address,
    double? latitude,
    double? longitude,
    String? salesmanId,
    String? routeId,
    String? area,
    String? imageUrl,
    String? notes,
    DateTime? createdAt,
    bool? approved,
    bool? active,
  }) {
    return Shop(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopkeeperName: shopkeeperName ?? this.shopkeeperName,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      salesmanId: salesmanId ?? this.salesmanId,
      routeId: routeId ?? this.routeId,
      area: area ?? this.area,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      approved: approved ?? this.approved,
      active: active ?? this.active,
    );
  }
}

