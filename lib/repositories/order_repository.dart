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
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository(this._firestore);

  @override
  Future<void> createOrder(Order order) async {
    // Write batch ensuring order metadata, items, and timeline initialization are recorded in single operation
    final batch = _firestore.batch();

    // 1. Root orders collection
    final orderRef = _firestore.collection('orders').doc(order.orderId);
    batch.set(orderRef, order.toJson());

    // Write initial timeline logs
    final timelineRef = orderRef.collection('timeline').doc();
    final timeline = OrderTimeline(
      timelineId: timelineRef.id,
      status: 'Placed',
      message: 'Order recorded by salesman.',
      updatedBy: order.salesmanId,
      timestamp: DateTime.now(),
    );
    batch.set(timelineRef, timeline.toJson());

    // 2. Salesman subcollection: /salesmen/{salesmanId}/orders/{orderId}
    final salesmanOrderRef = _firestore
        .collection('salesmen')
        .doc(order.salesmanId)
        .collection('orders')
        .doc(order.orderId);
    batch.set(salesmanOrderRef, order.toJson());

    final salesmanTimelineRef =
        salesmanOrderRef.collection('timeline').doc(timelineRef.id);
    batch.set(salesmanTimelineRef, timeline.toJson());

    // 3. /SalesmenOrders/{salesmanId}/{orderid}/order details
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
        .collection('orders')
        .where('salesmanId', isEqualTo: salesmanId)
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
        .collection('orders')
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
        .collection('orders')
        .doc(orderId)
        .collection('timeline')
        .orderBy('timestamp', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => OrderTimeline.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus,
    String message,
    String updatedBy,
  ) async {
    final batch = _firestore.batch();

    // Look up the salesmanId first to update all parallel copies of the order document in different paths
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    String? salesmanId;
    if (orderDoc.exists) {
      salesmanId = orderDoc.data()?['salesmanId'] as String?;
    }

    final orderRef = _firestore.collection('orders').doc(orderId);
    batch.update(orderRef, {
      'orderStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final timelineRef = orderRef.collection('timeline').doc();
    final timeline = OrderTimeline(
      timelineId: timelineRef.id,
      status: newStatus,
      message: message,
      updatedBy: updatedBy,
      timestamp: DateTime.now(),
    );
    batch.set(timelineRef, timeline.toJson());

    if (salesmanId != null && salesmanId.isNotEmpty) {
      // Update salesman subcollection
      final salesmanOrderRef = _firestore
          .collection('salesmen')
          .doc(salesmanId)
          .collection('orders')
          .doc(orderId);
      batch.update(salesmanOrderRef, {
        'orderStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final salesmanTimelineRef =
          salesmanOrderRef.collection('timeline').doc(timelineRef.id);
      batch.set(salesmanTimelineRef, timeline.toJson());

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
