import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/shop_model.dart';

class ShopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // ADD SHOP
  // =========================

  Future<void> addShop({required ShopModel shop}) async {
    await _firestore.collection("shops").doc(shop.id).set(shop.toMap());
  }

  // =========================
  // GET SHOPS
  // =========================

  Stream<List<ShopModel>> getShops() {
    final uid = _auth.currentUser?.uid ?? "";

    return _firestore
        .collection("shops")
        .where("createdBy", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ShopModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // =========================
  // DUPLICATE CHECK
  // =========================

  Future<bool> shopExists(String phone) async {
    final result = await _firestore
        .collection("shops")
        .where("phone", isEqualTo: phone)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }
}
