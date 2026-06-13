import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/core/widgets/custom_button.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/providers/cart_provider.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;

  const CartScreen({
    Key? key,
    required this.shopId,
    required this.shopName,
  }) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isPlacing = false;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _notesController.text = cart.notes;
    _discountController.text = cart.discountPercentage.toInt().toString();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final curSalesman = ref.read(salesmanProfileProvider).valueOrNull;
    if (curSalesman == null) return;

    setState(() {
      _isPlacing = true;
    });

    try {
      ref.read(cartProvider.notifier).setNotes(_notesController.text);
      
      double disc = double.tryParse(_discountController.text) ?? 0.0;
      ref.read(cartProvider.notifier).setDiscount(disc);

      await ref.read(cartProvider.notifier).submitOrder(
            salesmanId: curSalesman.uid,
            shopId: widget.shopId,
            shopName: widget.shopName,
          );

      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Bulk Sales Order Booked Successfully!',
          type: SnackbarType.success,
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacing = false;
        });
        CustomSnackbar.show(
          context,
          message: 'Failed to book sales order: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billed Items Basket'),
      ),
      body: cartState.itemQuantities.isEmpty
          ? _buildEmptyCartPlaceholder()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buying for: ${widget.shopName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 16),
                        _buildCartItemsList(cartState),
                        const SizedBox(height: 20),
                        _buildDiscountField(),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        _buildOrderDetailsSummaryCard(cartState),
                      ],
                    ),
                  ),
                ),
                _buildStickyBottomActionBar(cartState),
              ],
            ),
    );
  }

  Widget _buildEmptyCartPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('Your shopping cart is empty.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            child: const Text('Browse FMCG Catalog'),
            onPressed: () => context.pop(),
          )
        ],
      ),
    );
  }

  Widget _buildCartItemsList(CartState state) {
    final cartNotifier = ref.read(cartProvider.notifier);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.itemQuantities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final id = state.itemQuantities.keys.elementAt(idx);
          final p = state.products[id];
          final q = state.itemQuantities[id]!;

          if (p == null) return const SizedBox();

          return ListTile(
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Unit cost: ₹${p.wholesalePrice.toStringAsFixed(2)} • GST: ${p.gst}%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.blue),
                  onPressed: () => cartNotifier.updateQuantity(p.productId, q - 1),
                ),
                Text('$q', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
                  onPressed: () => cartNotifier.updateQuantity(p.productId, q + 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiscountField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.percent, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Apply Agent Cash Discount (%)',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  ref.read(cartProvider.notifier).setDiscount(parsed);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Delivery Instructions & Notes',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'e.g. deliver by Friday morning, pack in small bags...',
      ),
      maxLines: 2,
    );
  }

  Widget _buildOrderDetailsSummaryCard(CartState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bill Summary Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 24),
            _buildDetailSummaryRow('Original Subtotal:', '₹${state.subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildDetailSummaryRow('Applied Cash Discount:', '-₹${state.discountAmount.toStringAsFixed(2)}', valueStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDetailSummaryRow('Calculated GST Duties:', '+₹${state.totalGst.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildDetailSummaryRow(
              'Cumulative Grand Total:',
              '₹${state.grandTotal.toStringAsFixed(2)}',
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              valueStyle: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomActionBar(CartState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: 'Place Order (₹${state.grandTotal.toStringAsFixed(2)})',
          isLoading: _isPlacing,
          onPressed: _handlePlaceOrder,
        ),
      ),
    );
  }

  Widget _buildDetailSummaryRow(String label, String value, {TextStyle? labelStyle, TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

