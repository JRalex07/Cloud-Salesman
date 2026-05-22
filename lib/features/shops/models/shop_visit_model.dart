class ShopVisitModel {
  final String id;

  final String salesmanId;

  final String shopId;

  final String shopName;

  final DateTime checkInTime;

  final DateTime? checkOutTime;

  final double checkInLatitude;

  final double checkInLongitude;

  final double? checkOutLatitude;

  final double? checkOutLongitude;

  final bool active;

  ShopVisitModel({
    required this.id,
    required this.salesmanId,
    required this.shopId,
    required this.shopName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.checkOutLatitude,
    required this.checkOutLongitude,
    required this.active,
  });

  factory ShopVisitModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopVisitModel(
      id: id,

      salesmanId: map["salesmanId"] ?? "",

      shopId: map["shopId"] ?? "",

      shopName: map["shopName"] ?? "",

      checkInTime: DateTime.parse(map["checkInTime"]),

      checkOutTime: map["checkOutTime"] != null
          ? DateTime.parse(map["checkOutTime"])
          : null,

      checkInLatitude: (map["checkInLatitude"] ?? 0).toDouble(),

      checkInLongitude: (map["checkInLongitude"] ?? 0).toDouble(),

      checkOutLatitude: map["checkOutLatitude"] != null
          ? (map["checkOutLatitude"] ?? 0).toDouble()
          : null,

      checkOutLongitude: map["checkOutLongitude"] != null
          ? (map["checkOutLongitude"] ?? 0).toDouble()
          : null,

      active: map["active"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "salesmanId": salesmanId,

      "shopId": shopId,

      "shopName": shopName,

      "checkInTime": checkInTime.toIso8601String(),

      "checkOutTime": checkOutTime?.toIso8601String(),

      "checkInLatitude": checkInLatitude,

      "checkInLongitude": checkInLongitude,

      "checkOutLatitude": checkOutLatitude,

      "checkOutLongitude": checkOutLongitude,

      "active": active,
    };
  }
}
