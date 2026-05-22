class OrderItemModel {
  final String productId;

  final String productName;

  final int quantity;

  final double price;

  final double total;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map["productId"] ?? "",

      productName: map["productName"] ?? "",

      quantity: map["quantity"] ?? 0,

      price: (map["price"] ?? 0).toDouble(),

      total: (map["total"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "productId": productId,

      "productName": productName,

      "quantity": quantity,

      "price": price,

      "total": total,
    };
  }
}

class OrderModel {
  final String id;

  final String salesmanId;

  final String shopId;

  final String shopName;

  final double totalAmount;

  final String status;

  final DateTime createdAt;

  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.salesmanId,
    required this.shopId,
    required this.shopName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,

      salesmanId: map["salesmanId"] ?? "",

      shopId: map["shopId"] ?? "",

      shopName: map["shopName"] ?? "",

      totalAmount: (map["totalAmount"] ?? 0).toDouble(),

      status: map["status"] ?? "",

      createdAt: DateTime.parse(map["createdAt"]),

      items: (map["items"] as List)
          .map((e) => OrderItemModel.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "salesmanId": salesmanId,

      "shopId": shopId,

      "shopName": shopName,

      "totalAmount": totalAmount,

      "status": status,

      "createdAt": createdAt.toIso8601String(),

      "items": items.map((e) => e.toMap()).toList(),
    };
  }
}
