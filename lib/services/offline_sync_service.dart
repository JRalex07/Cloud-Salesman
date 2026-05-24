import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/visit.dart';
import '../repositories/order_repository.dart';
import '../repositories/visit_repository.dart';

class OfflineSyncService {
  final OrderRepository _orderRepo;
  final VisitRepository _visitRepo;

  // In-memory queues backing offline updates
  final List<Order> _offlineOrdersQueue = [];
  final List<Map<String, dynamic>> _offlineVisitsQueue = [];

  OfflineSyncService(this._orderRepo, this._visitRepo);

  // Queue Order when offline
  void queueOfflineOrder(Order order) {
    _offlineOrdersQueue.add(order);
    if (kDebugMode) {
      print(
          'Offline order queued: ${order.orderId}. Total in queue: ${_offlineOrdersQueue.length}');
    }
  }

  // Queue Visit when offline
  void queueOfflineVisit(String salesmanId, Visit visit) {
    _offlineVisitsQueue.add({
      'salesmanId': salesmanId,
      'visit': visit,
    });
    if (kDebugMode) {
      print(
          'Offline visit queued: ${visit.visitId}. Total in queue: ${_offlineVisitsQueue.length}');
    }
  }

  // Check queues
  int get pendingOrdersCount => _offlineOrdersQueue.length;
  int get pendingVisitsCount => _offlineVisitsQueue.length;

  // Trigger synchronize
  Future<void> synchronizeQueues() async {
    if (_offlineOrdersQueue.isEmpty && _offlineVisitsQueue.isEmpty) return;

    // Replay orders
    final List<Order> ordersToSync = List.from(_offlineOrdersQueue);
    for (var order in ordersToSync) {
      try {
        await _orderRepo.createOrder(order);
        _offlineOrdersQueue.remove(order);
      } catch (e) {
        if (kDebugMode) print('Failed to sync order ${order.orderId}: $e');
        // Stop syncing this flow to preserve sequence integrity
        break;
      }
    }

    // Replay visits
    final List<Map<String, dynamic>> visitsToSync =
        List.from(_offlineVisitsQueue);
    for (var item in visitsToSync) {
      try {
        final salesmanId = item['salesmanId'] as String;
        final visit = item['visit'] as Visit;
        await _visitRepo.checkIn(salesmanId, visit);
        _offlineVisitsQueue.remove(item);
      } catch (e) {
        if (kDebugMode) print('Failed to sync visit: $e');
        break;
      }
    }
  }
}
