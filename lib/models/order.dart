import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price; // unit price (wholesale or retail as relevant)
  final double gstPercentage;
  final double gstAmount;
  final double total;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.gstPercentage,
    required this.gstAmount,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'total': total,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Order {
  final String orderId;
  final String salesmanId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double gst; // total accumulated GST
  final double total;
  final String paymentStatus; // 'Pending', 'Paid', 'PartiallyPaid'
  final String orderStatus;   // 'Pending', 'Approved', 'Packed', 'Shipped', 'Delivered', 'Cancelled'
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.orderId,
    required this.salesmanId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.total,
    required this.paymentStatus,
    required this.orderStatus,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'salesmanId': salesmanId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'gst': gst,
      'total': total,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItem> parsedItems = rawItems
        .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return Order(
      orderId: json['orderId'] ?? '',
      salesmanId: json['salesmanId'] ?? '',
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      items: parsedItems,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      orderStatus: json['orderStatus'] ?? 'Pending',
      notes: json['notes'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Order copyWith({
    String? orderId,
    String? salesmanId,
    String? shopId,
    String? shopName,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? gst,
    double? total,
    String? paymentStatus,
    String? orderStatus,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      salesmanId: salesmanId ?? this.salesmanId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      gst: gst ?? this.gst,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

