import 'package:flutter/material.dart';

import '../../../shared/models/order_model.dart';

import '../../../shared/models/product_model.dart';

import '../../products/data/product_repository.dart';

import '../data/order_repository.dart';

import '../widgets/cart_item_tile.dart';

import '../widgets/order_summary.dart';

class CreateOrderScreen extends StatefulWidget {
  final String shopId;

  final String shopName;

  const CreateOrderScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final productRepository = ProductRepository();

  final orderRepository = OrderRepository();

  final List<OrderItemModel> cartItems = [];

  bool placingOrder = false;

  // =========================
  // ADD PRODUCT
  // =========================

  void addProduct(ProductModel product) {
    final index = cartItems.indexWhere((e) => e.productId == product.id);

    // already added

    if (index >= 0) {
      final old = cartItems[index];

      final updated = OrderItemModel(
        productId: old.productId,

        productName: old.productName,

        quantity: old.quantity + 1,

        price: old.price,

        total: (old.quantity + 1) * old.price,
      );

      setState(() {
        cartItems[index] = updated;
      });

      return;
    }

    // new item

    setState(() {
      cartItems.add(
        OrderItemModel(
          productId: product.id,

          productName: product.name,

          quantity: 1,

          price: product.wholesalePrice,

          total: product.wholesalePrice,
        ),
      );
    });
  }

  // =========================
  // INCREASE QTY
  // =========================

  void increaseQty(int index) {
    final item = cartItems[index];

    setState(() {
      cartItems[index] = OrderItemModel(
        productId: item.productId,

        productName: item.productName,

        quantity: item.quantity + 1,

        price: item.price,

        total: (item.quantity + 1) * item.price,
      );
    });
  }

  // =========================
  // DECREASE QTY
  // =========================

  void decreaseQty(int index) {
    final item = cartItems[index];

    // remove item

    if (item.quantity <= 1) {
      setState(() {
        cartItems.removeAt(index);
      });

      return;
    }

    setState(() {
      cartItems[index] = OrderItemModel(
        productId: item.productId,

        productName: item.productName,

        quantity: item.quantity - 1,

        price: item.price,

        total: (item.quantity - 1) * item.price,
      );
    });
  }

  // =========================
  // TOTAL
  // =========================

  double get total {
    double value = 0;

    for (final item in cartItems) {
      value += item.total;
    }

    return value;
  }

  // =========================
  // PLACE ORDER
  // =========================

  Future<void> placeOrder() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add products first")));

      return;
    }

    setState(() {
      placingOrder = true;
    });

    try {
      await orderRepository.createOrder(
        shopId: widget.shopId,

        shopName: widget.shopName,

        items: cartItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        placingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName)),

      body: Column(
        children: [
          // =====================
          // PRODUCTS
          // =====================
          Expanded(
            child: StreamBuilder(
              stream: productRepository.getProducts(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!;

                if (products.isEmpty) {
                  return const Center(child: Text("No products available"));
                }

                return ListView.builder(
                  itemCount: products.length,

                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.image),
                        ),

                        title: Text(product.name),

                        subtitle: Text("₹${product.wholesalePrice}"),

                        trailing: ElevatedButton(
                          onPressed: () {
                            addProduct(product);
                          },

                          child: const Text("ADD"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // =====================
          // CART
          // =====================
          if (cartItems.isNotEmpty)
            Container(
              height: 280,

              decoration: BoxDecoration(
                color: Colors.grey.shade100,

                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),

              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),

                    child: Row(
                      children: [
                        const Text(
                          "Cart",

                          style: TextStyle(
                            fontSize: 22,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        Text("${cartItems.length} items"),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,

                      itemBuilder: (context, index) {
                        final item = cartItems[index];

                        return CartItemTile(
                          item: item,

                          onAdd: () {
                            increaseQty(index);
                          },

                          onRemove: () {
                            decreaseQty(index);
                          },
                        );
                      },
                    ),
                  ),

                  OrderSummary(
                    total: total,

                    onSubmit: placingOrder ? () {} : placeOrder,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
