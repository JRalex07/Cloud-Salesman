import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/models/product.dart';
import 'package:cloud_power_salesman/models/category.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

abstract class ProductRepository {
  Stream<List<Product>> getActiveProducts();
  Future<List<Product>> getProductsByCategory(String category);
  Future<Product> getProductById(String productId);
  Future<void> updateStock(String productId, int quantityChange);
  Stream<List<Category>> getCategories();
}

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirebaseProductRepository(this._firestore);

  @override
  Stream<List<Product>> getActiveProducts() {
    _checkAndSeedProducts();
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromJson(doc.data(), id: doc.id))
            .where((p) => p.active)
            .toList());
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    await _checkAndSeedProducts();
    final snapshot = await _firestore.collection('products').get();

    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data(), id: doc.id))
        .where((p) => p.active && (category == 'All' || p.category == category))
        .toList();
  }

  @override
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Category.fromJson(doc.data(), id: doc.id))
              .where((c) => c.isActive)
              .toList();
          list.sort((a, b) => a.priority.compareTo(b.priority));
          return list;
        });
  }

  Future<void> _checkAndSeedProducts() async {
    try {
      final snapshot = await _firestore.collection('products').limit(1).get();
      if (snapshot.docs.isEmpty) {
        await _seedInitialProducts();
      }
    } catch (e) {
      // Ignore/log seeding errors safely
    }
  }

  Future<void> _seedInitialProducts() async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    
    final initialProducts = [
      // Beverages
      Product(
        productId: 'bev_cola_500',
        name: 'Classic Brand Cola 500ml',
        description: 'Refreshing carbonated zero-sugar cola beverage.',
        image: '',
        category: 'Beverages',
        wholesalePrice: 1.10,
        retailPrice: 1.50,
        stock: 100,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'bev_energy_250',
        name: 'Energy Monster 250ml',
        description: 'Power-packed taurine and ginseng energy drink.',
        image: '',
        category: 'Beverages',
        wholesalePrice: 1.80,
        retailPrice: 2.50,
        stock: 75,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'bev_water_1000',
        name: 'Spring Mineral Water 1L',
        description: 'Pure, natural, and oxygen-rich underground spring water.',
        image: '',
        category: 'Beverages',
        wholesalePrice: 0.60,
        retailPrice: 0.99,
        stock: 150,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'bev_juice_1000',
        name: 'Mango Splash Juice 1L',
        description: '100% natural, sweet, and pulpy alphonso mango juice.',
        image: '',
        category: 'Beverages',
        wholesalePrice: 1.60,
        retailPrice: 2.20,
        stock: 60,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'bev_tea_500',
        name: 'Organic Green Tea 500ml',
        description: 'Fresh brewed organic green tea with honey and lemon.',
        image: '',
        category: 'Beverages',
        wholesalePrice: 1.30,
        retailPrice: 1.80,
        stock: 80,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),

      // Snacks
      Product(
        productId: 'sn_chips_classic',
        name: 'Classic Salted Potato Chips',
        description: 'Crisp, golden-fried salted potato single-serve packs.',
        image: '',
        category: 'Snacks',
        wholesalePrice: 0.80,
        retailPrice: 1.20,
        stock: 120,
        gst: 12.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'sn_nacho_cheese',
        name: 'Nacho Cheese Tortillas',
        description: 'Stone-ground corn tortillas baked with sharp cheddar seasoning.',
        image: '',
        category: 'Snacks',
        wholesalePrice: 1.10,
        retailPrice: 1.60,
        stock: 90,
        gst: 12.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'sn_almonds_200',
        name: 'Roasted Salted Almonds 200g',
        description: 'Premium whole California almonds slow-roasted and salted.',
        image: '',
        category: 'Snacks',
        wholesalePrice: 3.20,
        retailPrice: 4.50,
        stock: 50,
        gst: 12.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'sn_popcorn_100',
        name: 'Spicy Popcorn 100g',
        description: 'Air-popped yellow corn with a spicy sweet chili rub.',
        image: '',
        category: 'Snacks',
        wholesalePrice: 0.70,
        retailPrice: 1.10,
        stock: 110,
        gst: 12.0,
        active: true,
        createdAt: now,
      ),

      // Dairies
      Product(
        productId: 'dy_milk_1000',
        name: 'Fresh Whole Milk 1L',
        description: 'Pasteurized, homogenized pure cow milk with essential Vitamin D.',
        image: '',
        category: 'Dairies',
        wholesalePrice: 1.00,
        retailPrice: 1.40,
        stock: 80,
        gst: 5.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'dy_butter_500',
        name: 'Salted Dairy Butter 500g',
        description: 'Creamy, rich premium table butter churned with sea salt.',
        image: '',
        category: 'Dairies',
        wholesalePrice: 2.40,
        retailPrice: 3.20,
        stock: 45,
        gst: 5.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'dy_cheese_250',
        name: 'Cheddar Cheese Block 250g',
        description: 'Aged sharp cheddar cheese block with intense complex bite.',
        image: '',
        category: 'Dairies',
        wholesalePrice: 2.60,
        retailPrice: 3.50,
        stock: 60,
        gst: 5.0,
        active: true,
        createdAt: now,
      ),

      // Household
      Product(
        productId: 'hh_dish_wash_500',
        name: 'Ultra Dishwasher Liquid 500ml',
        description: 'Concentrated lemon grease-cutting detergent with skin moisturizers.',
        image: '',
        category: 'Household',
        wholesalePrice: 1.25,
        retailPrice: 1.75,
        stock: 70,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'hh_laundry_1000',
        name: 'Eco Laundry Detergent 1L',
        description: 'Plant-derived, dye-free, high-efficiency liquid detergent formulation.',
        image: '',
        category: 'Household',
        wholesalePrice: 3.90,
        retailPrice: 5.50,
        stock: 35,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),

      // Confectionery
      Product(
        productId: 'cf_chocolate_100',
        name: 'Milk Chocolate Bar 100g',
        description: 'Silky smooth alpine milk chocolate with premium cocoa solids.',
        image: '',
        category: 'Confectionery',
        wholesalePrice: 1.00,
        retailPrice: 1.50,
        stock: 140,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
      Product(
        productId: 'cf_caramel_candy',
        name: 'Peanut Caramel Candy Bar',
        description: 'Chewy, sweet milk caramel filled with freshly roasted peanuts.',
        image: '',
        category: 'Confectionery',
        wholesalePrice: 0.65,
        retailPrice: 0.99,
        stock: 200,
        gst: 18.0,
        active: true,
        createdAt: now,
      ),
    ];

    for (final prod in initialProducts) {
      final docRef = _firestore.collection('products').doc(prod.productId);
      batch.set(docRef, prod.toJson());
    }

    await batch.commit();
  }

  @override
  Future<Product> getProductById(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Product SKU not found');
    }
    return Product.fromJson(doc.data()!, id: doc.id);
  }

  @override
  Future<void> updateStock(String productId, int quantityChange) async {
    // Uses direct server atomic transaction to prevent concurrent stock issues
    final docRef = _firestore.collection('products').doc(productId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        int currentStock = snapshot.data()?['stock'] ?? 0;
        transaction.update(docRef, {'stock': currentStock + quantityChange});
      }
    });
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirebaseProductRepository(ref.watch(firestoreProvider));
});

