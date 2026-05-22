class ProductModel {
  final String id;

  final String name;

  final String description;

  final double wholesalePrice;

  final double retailPrice;

  final int stock;

  final String image;

  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.stock,
    required this.image,
    required this.isActive,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,

      name: map["name"] ?? "",

      description: map["description"] ?? "",

      wholesalePrice: (map["wholesalePrice"] ?? 0).toDouble(),

      retailPrice: (map["retailPrice"] ?? 0).toDouble(),

      stock: map["stock"] ?? 0,

      image: map["image"] ?? "",

      isActive: map["isActive"] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,

      "description": description,

      "wholesalePrice": wholesalePrice,

      "retailPrice": retailPrice,

      "stock": stock,

      "image": image,

      "isActive": isActive,
    };
  }
}
