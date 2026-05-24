import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../repositories/order_repository.dart';
import 'sync_provider.dart';

class CartState {
  final Map<String, int> itemQuantities; // productId -> quantity
  final Map<String, Product> products; // productId -> Product metadata
  final double discountPercentage;
  final String notes;

  CartState({
    required this.itemQuantities,
    required this.products,
    required this.discountPercentage,
    required this.notes,
  });

  CartState copyWith({
    Map<String, int>? itemQuantities,
    Map<String, Product>? products,
    double? discountPercentage,
    String? notes,
  }) {
    return CartState(
      itemQuantities: itemQuantities ?? this.itemQuantities,
      products: products ?? this.products,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      notes: notes ?? this.notes,
    );
  }

  // Getters for live math calculations required for FMCG orders
  double get subtotal {
    double total = 0.0;
    itemQuantities.forEach((id, q) {
      final p = products[id];
      if (p != null) {
        total += p.wholesalePrice * q;
      }
    });
    return total;
  }

  double get discountAmount {
    return subtotal * (discountPercentage / 100.0);
  }

  double get totalGst {
    double gstAccumulator = 0.0;
    final discountedSubtotal = subtotal - discountAmount;
    if (subtotal == 0) return 0.0;

    itemQuantities.forEach((id, q) {
      final p = products[id];
      if (p != null) {
        // Apportion discount proportional to item value to apply progressive tax accurately
        final double itemValue = p.wholesalePrice * q;
        final double share = itemValue / subtotal;
        final double itemShareDiscount = discountAmount * share;
        final double taxableBase = itemValue - itemShareDiscount;

        gstAccumulator += taxableBase * (p.gst / 100.0);
      }
    });
    return gstAccumulator;
  }

  double get grandTotal {
    return (subtotal - discountAmount) + totalGst;
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref _ref;

  CartNotifier(this._ref)
      : super(
          CartState(
            itemQuantities: {},
            products: {},
            discountPercentage: 0.0,
            notes: '',
          ),
        );

  void addItem(Product product) {
    final quantities = Map<String, int>.from(state.itemQuantities);
    final prods = Map<String, Product>.from(state.products);

    quantities[product.productId] = (quantities[product.productId] ?? 0) + 1;
    prods[product.productId] = product;

    state = state.copyWith(itemQuantities: quantities, products: prods);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final quantities = Map<String, int>.from(state.itemQuantities);
    quantities[productId] = quantity;

    state = state.copyWith(itemQuantities: quantities);
  }

  void removeItem(String productId) {
    final quantities = Map<String, int>.from(state.itemQuantities);
    final prods = Map<String, Product>.from(state.products);

    quantities.remove(productId);
    prods.remove(productId);

    state = state.copyWith(itemQuantities: quantities, products: prods);
  }

  void setDiscount(double discountPercent) {
    state = state.copyWith(discountPercentage: discountPercent);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearCart() {
    state = CartState(
      itemQuantities: {},
      products: {},
      discountPercentage: 0.0,
      notes: '',
    );
  }

  Future<void> submitOrder({
    required String salesmanId,
    required String shopId,
    required String shopName,
  }) async {
    if (state.itemQuantities.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final String uniqueOrderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
    final List<OrderItem> orderItems = [];

    state.itemQuantities.forEach((id, q) {
      final p = state.products[id];
      if (p != null) {
        final double value = p.wholesalePrice * q;
        final double share = value / state.subtotal;
        final double shareDiscount = state.discountAmount * share;
        final double taxableBase = value - shareDiscount;
        final double computedGstAmount = taxableBase * (p.gst / 100.0);

        orderItems.add(
          OrderItem(
            productId: id,
            name: p.name,
            quantity: q,
            price: p.wholesalePrice,
            gstPercentage: p.gst,
            gstAmount: computedGstAmount,
            total: value - shareDiscount + computedGstAmount,
          ),
        );
      }
    });

    final order = Order(
      orderId: uniqueOrderId,
      salesmanId: salesmanId,
      shopId: shopId,
      shopName: shopName,
      items: orderItems,
      subtotal: state.subtotal,
      discount: state.discountAmount,
      gst: state.totalGst,
      total: state.grandTotal,
      paymentStatus: 'Pending',
      orderStatus: 'Pending',
      notes: state.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final syncState = _ref.read(syncProvider);
    if (syncState.isOnline) {
      try {
        await _ref.read(orderRepositoryProvider).createOrder(order);
      } catch (e) {
        // Enforce progressive resilience: if real Firestore save fails, route to sync queue automatically
        _ref.read(syncProvider.notifier).queueOrderOffline(order);
      }
    } else {
      _ref.read(syncProvider.notifier).queueOrderOffline(order);
    }

    clearCart();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
