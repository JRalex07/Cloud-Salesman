import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_power_salesman/models/order.dart';
import 'package:cloud_power_salesman/models/order_timeline.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

abstract class OrderRepository {
  Future<void> createOrder(Order order);
  Stream<List<Order>> getOrdersBySalesman(String salesmanId);
  Stream<List<Order>> getOrdersByShop(String shopId);
  Future<List<OrderTimeline>> getOrderTimeline(String orderId);
  Future<void> updateOrderStatus(
      String orderId, String newStatus, String message, String updatedBy);
  Future<void> updatePaymentStatus(
      String orderId, String newStatus, String updatedBy);
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository(this._firestore);

  @override
  Future<void> createOrder(Order order) async {
    // Write batch ensuring order metadata, items, and timeline initialization are recorded in single operation
    final batch = _firestore.batch();

    // 1. Salesman subcollection: /salesmen/{salesmanId}/orders/{orderId}
    final salesmanOrderRef = _firestore
        .collection('salesmen')
        .doc(order.salesmanId)
        .collection('orders')
        .doc(order.orderId);
    batch.set(salesmanOrderRef, order.toJson());

    // Write initial timeline logs
    final timelineRef = salesmanOrderRef.collection('timeline').doc();
    final timeline = OrderTimeline(
      timelineId: timelineRef.id,
      status: 'Placed',
      message: 'Order recorded by salesman.',
      updatedBy: order.salesmanId,
      timestamp: DateTime.now(),
    );
    batch.set(timelineRef, timeline.toJson());

    // 2. /SalesmenOrders/{salesmanId}/{orderid}/order details
    final salesmenOrdersRef = _firestore
        .collection('SalesmenOrders')
        .doc(order.salesmanId)
        .collection(order.orderId)
        .doc('order details');
    batch.set(salesmenOrdersRef, order.toJson());

    final salesmenOrdersTimelineRef =
        salesmenOrdersRef.collection('timeline').doc(timelineRef.id);
    batch.set(salesmenOrdersTimelineRef, timeline.toJson());

    // Deduct stock levels for items ordered using atomic Firestore updates
    for (var item in order.items) {
      final productRef = _firestore.collection('products').doc(item.productId);
      batch.update(productRef, {
        'stock': FieldValue.increment(-item.quantity),
      });
    }

    await batch.commit();
  }

  @override
  Stream<List<Order>> getOrdersBySalesman(String salesmanId) {
    return _firestore
        .collection('salesmen')
        .doc(salesmanId)
        .collection('orders')
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Stream<List<Order>> getOrdersByShop(String shopId) {
    return _firestore
        .collectionGroup('orders')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => Order.fromJson(doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<OrderTimeline>> getOrderTimeline(String orderId) async {
    final snapshot = await _firestore
        .collectionGroup('orders')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final timelineSnapshot = await snapshot.docs.first.reference
        .collection('timeline')
        .orderBy('timestamp', descending: false)
        .get();

    return timelineSnapshot.docs
        .map((doc) => OrderTimeline.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> updatePaymentStatus(
      String orderId, String newStatus, String updatedBy) async {
    final batch = _firestore.batch();

    // Look up the order doc in any salesman path
    final snapshot = await _firestore
        .collectionGroup('orders')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final salesmanOrderRef = snapshot.docs.first.reference;
    final orderData = snapshot.docs.first.data();
    final salesmanId = orderData['salesmanId'] as String?;

    batch.update(salesmanOrderRef, {
      'paymentStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final timelineRef = salesmanOrderRef.collection('timeline').doc();
    final timeline = OrderTimeline(
      timelineId: timelineRef.id,
      status: 'Payment Update',
      message: 'Payment status updated to $newStatus',
      updatedBy: updatedBy,
      timestamp: DateTime.now(),
    );
    batch.set(timelineRef, timeline.toJson());

    if (salesmanId != null && salesmanId.isNotEmpty) {
      // Update /SalesmenOrders path
      final salesmenOrdersRef = _firestore
          .collection('SalesmenOrders')
          .doc(salesmanId)
          .collection(orderId)
          .doc('order details');
      batch.update(salesmenOrdersRef, {
        'paymentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(salesmenOrdersRef.collection('timeline').doc(timelineRef.id),
          timeline.toJson());
    }

    await batch.commit();
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String message,
    String updatedBy,
  ) async {
    final batch = _firestore.batch();

    // Look up the order doc in any salesman path
    final snapshot = await _firestore
        .collectionGroup('orders')
        .where('orderId', isEqualTo: orderId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final salesmanOrderRef = snapshot.docs.first.reference;
    final orderData = snapshot.docs.first.data();
    final salesmanId = orderData['salesmanId'] as String?;

    batch.update(salesmanOrderRef, {
      'orderStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final timelineRef = salesmanOrderRef.collection('timeline').doc();
    final timeline = OrderTimeline(
      timelineId: timelineRef.id,
      status: newStatus,
      message: message,
      updatedBy: updatedBy,
      timestamp: DateTime.now(),
    );
    batch.set(timelineRef, timeline.toJson());

    if (salesmanId != null && salesmanId.isNotEmpty) {
      // Update /SalesmenOrders/{salesmanId}/{orderid}/order details
      final salesmenOrdersRef = _firestore
          .collection('SalesmenOrders')
          .doc(salesmanId)
          .collection(orderId)
          .doc('order details');
      batch.update(salesmenOrdersRef, {
        'orderStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final salesmenOrdersTimelineRef =
          salesmenOrdersRef.collection('timeline').doc(timelineRef.id);
      batch.set(salesmenOrdersTimelineRef, timeline.toJson());
    }

    await batch.commit();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirebaseOrderRepository(ref.watch(firestoreProvider));
});
