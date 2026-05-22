import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================
  // CREATE ORDER
  // =========================

  Future<void> createOrder({
    required String shopId,
    required String shopName,
    required List<OrderItemModel> items,
  }) async {
    final uid = _auth.currentUser!.uid;

    double total = 0;

    for (final item in items) {
      total += item.total;
    }

    final order = OrderModel(
      id: "",

      salesmanId: uid,

      shopId: shopId,

      shopName: shopName,

      totalAmount: total,

      status: "pending",

      createdAt: DateTime.now(),

      items: items,
    );

    await _firestore.collection("orders").add(order.toMap());
  }

  // =========================
  // ORDER HISTORY
  // =========================

  Stream<List<OrderModel>> getOrders() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection("orders")
        .where("salesmanId", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
