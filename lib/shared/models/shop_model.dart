class ShopModel {
  final String id;

  final String shopName;

  final String ownerName;

  final String phone;

  final String address;

  final double latitude;

  final double longitude;

  final String image;

  final String createdBy;

  final DateTime createdAt;

  final bool approved;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.image,
    required this.createdBy,
    required this.createdAt,
    required this.approved,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      id: id,

      shopName: map["shopName"] ?? "",

      ownerName: map["ownerName"] ?? "",

      phone: map["phone"] ?? "",

      address: map["address"] ?? "",

      latitude: (map["latitude"] ?? 0).toDouble(),

      longitude: (map["longitude"] ?? 0).toDouble(),

      image: map["image"] ?? "",

      createdBy: map["createdBy"] ?? "",

      createdAt: DateTime.parse(map["createdAt"]),

      approved: map["approved"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "shopName": shopName,

      "ownerName": ownerName,

      "phone": phone,

      "address": address,

      "latitude": latitude,

      "longitude": longitude,

      "image": image,

      "createdBy": createdBy,

      "createdAt": createdAt.toIso8601String(),

      "approved": approved,
    };
  }
}
