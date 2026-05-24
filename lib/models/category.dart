import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String categoryId;
  final String name;
  final String image;
  final bool isActive;
  final int priority;
  final String slug;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.categoryId,
    required this.name,
    required this.image,
    required this.isActive,
    required this.priority,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'image': image,
      'isActive': isActive,
      'priority': priority,
      'slug': slug,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json, {String? id}) {
    return Category(
      categoryId: id ?? json['categoryId'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? json['active'] ?? false,
      priority: json['priority'] ?? 0,
      slug: json['slug'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Category copyWith({
    String? categoryId,
    String? name,
    String? image,
    bool? isActive,
    int? priority,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
