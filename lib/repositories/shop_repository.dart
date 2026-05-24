import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../providers/global_providers.dart';

abstract class ShopRepository {
  Stream<List<Shop>> getShopsStream();
  Stream<List<Shop>> getShopsByRouteIdStream(String routeId);
  Future<Shop> getShopById(String shopId);
  Future<void> addShop(Shop shop, {dynamic imageFile}); // dynamic to support File (mobile) or Uint8List (web)
  Future<void> updateShop(Shop shop);
  Future<List<Shop>> searchShops(String query);
}

class FirebaseShopRepository implements ShopRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseShopRepository(this._firestore, this._storage);

  @override
  Stream<List<Shop>> getShopsStream() {
    return _firestore
        .collection('shops')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Shop.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<Shop>> getShopsByRouteIdStream(String routeId) {
    return _firestore
        .collection('shops')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Shop.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<Shop> getShopById(String shopId) async {
    final doc = await _firestore.collection('shops').doc(shopId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Shop not found');
    }
    return Shop.fromJson(doc.data()!);
  }

  @override
  Future<void> addShop(Shop shop, {dynamic imageFile}) async {
    String finalUrl = shop.imageUrl;

    if (imageFile != null) {
      final String imagePath = 'shops/${shop.shopId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(imagePath);
      
      UploadTask uploadTask;
      if (imageFile is File) {
        uploadTask = ref.putFile(imageFile);
      } else {
        // Assume Web binary list (Uint8List)
        uploadTask = ref.putData(imageFile);
      }
      final TaskSnapshot snap = await uploadTask;
      finalUrl = await snap.ref.getDownloadURL();
    }

    final updatedShop = shop.copyWith(imageUrl: finalUrl);

    await _firestore
        .collection('shops')
        .doc(updatedShop.shopId)
        .set(updatedShop.toJson());
  }

  @override
  Future<void> updateShop(Shop shop) async {
    await _firestore
        .collection('shops')
        .doc(shop.shopId)
        .update(shop.toJson());
  }

  @override
  Future<List<Shop>> searchShops(String query) async {
    if (query.isEmpty) return [];
    // Standard basic text match queries (production Firestore matches prefixes)
    final snapshot = await _firestore
        .collection('shops')
        .where('shopName', isGreaterThanOrEqualTo: query)
        .where('shopName', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) => Shop.fromJson(doc.data())).toList();
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return FirebaseShopRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

