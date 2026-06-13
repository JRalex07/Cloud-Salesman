import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_power_salesman/repositories/order_repository.dart';
import 'package:cloud_power_salesman/repositories/visit_repository.dart';
import 'package:cloud_power_salesman/services/offline_sync_service.dart';

// State representing synchronization health
class SyncState {
  final int pendingOrders;
  final int pendingVisits;
  final bool isSyncing;
  final String? errorMessage;
  final bool isOnline;

  SyncState({
    required this.pendingOrders,
    required this.pendingVisits,
    required this.isSyncing,
    this.errorMessage,
    required this.isOnline,
  });

  SyncState copyWith({
    int? pendingOrders,
    int? pendingVisits,
    bool? isSyncing,
    String? errorMessage,
    bool? isOnline,
  }) {
    return SyncState(
      pendingOrders: pendingOrders ?? this.pendingOrders,
      pendingVisits: pendingVisits ?? this.pendingVisits,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage ?? this.errorMessage,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final OfflineSyncService _syncService;
  Timer? _heartbeatTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncNotifier(this._syncService)
      : super(SyncState(
          pendingOrders: 0,
          pendingVisits: 0,
          isSyncing: false,
          isOnline: true,
        )) {
    _startConnectivityLoop();
  }

  void _startConnectivityLoop() {
    // Check initial connectivity status asynchronously outside the evaluation/build frame
    Future.microtask(() async {
      try {
        final results = await Connectivity().checkConnectivity();
        final isNowOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
        updateConnectionStatus(isNowOnline);
      } catch (_) {}
    });

    // Listen for live connectivity status updates
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isNowOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      updateConnectionStatus(isNowOnline);
    });

    // Check signals and sync queue every 15 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await autoSync();
    });
  }

  void updateConnectionStatus(bool online) {
    state = state.copyWith(isOnline: online);
    if (online) {
      autoSync();
    }
  }

  Future<void> autoSync() async {
    if (!state.isOnline || state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      await _syncService.synchronizeQueues();
      state = SyncState(
        pendingOrders: _syncService.pendingOrdersCount,
        pendingVisits: _syncService.pendingVisitsCount,
        isSyncing: false,
        isOnline: state.isOnline,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Sync sync loop failed: ${e.toString()}',
      );
    }
  }

  void queueOrderOffline(dynamic order) {
    _syncService.queueOfflineOrder(order);
    state = state.copyWith(
      pendingOrders: _syncService.pendingOrdersCount,
    );
  }

  void queueVisitOffline(String salesmanId, dynamic visit) {
    _syncService.queueOfflineVisit(salesmanId, visit);
    state = state.copyWith(
      pendingVisits: _syncService.pendingVisitsCount,
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Global provider for Sync State
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    ref.watch(orderRepositoryProvider),
    ref.watch(visitRepositoryProvider),
  );
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref.watch(offlineSyncServiceProvider));
});

