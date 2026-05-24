import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String productId;
  final String name;
  final String description;
  final String image;
  final String category;
  final double wholesalePrice;
  final double retailPrice;
  final int stock;
  final double gst; // GST percentage (e.g. 18.0)
  final bool active;
  final DateTime createdAt;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.image,
    required this.category,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.stock,
    required this.gst,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'image': image,
      'category': category,
      'wholesalePrice': wholesalePrice,
      'retailPrice': retailPrice,
      'stock': stock,
      'gst': gst,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json, {String? id}) {
    final parsedImage = json['image'] ?? '';
    final imagesList = json['images'];
    final fallbackImage = (imagesList is List && imagesList.isNotEmpty)
        ? imagesList[0].toString()
        : '';

    return Product(
      productId: id ?? json['productId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      image: parsedImage.isNotEmpty ? parsedImage : fallbackImage,
      category: json['category'] ?? '',
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          (json['mrp'] as num?)?.toDouble() ??
          (json['sellPrice'] as num?)?.toDouble() ??
          0.0,
      retailPrice: (json['retailPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          (json['mrp'] as num?)?.toDouble() ??
          (json['sellPrice'] as num?)?.toDouble() ??
          0.0,
      stock: json['stock'] ?? json['quantity'] ?? 0,
      gst: (json['gst'] as num?)?.toDouble() ??
          (json['tax'] as num?)?.toDouble() ??
          0.0,
      active: json['isActive'] ?? json['active'] ?? false,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Product copyWith({
    String? productId,
    String? name,
    String? description,
    String? image,
    String? category,
    double? wholesalePrice,
    double? retailPrice,
    int? stock,
    double? gst,
    bool? active,
    DateTime? createdAt,
  }) {
    return Product(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      stock: stock ?? this.stock,
      gst: gst ?? this.gst,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
