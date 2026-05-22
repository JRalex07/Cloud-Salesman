import 'package:flutter/material.dart';

import '../../../shared/models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Text(
            order.shopName,

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          ...order.items.map((item) {
            return Card(
              child: ListTile(
                title: Text(item.productName),

                subtitle: Text("Qty: ${item.quantity}"),

                trailing: Text("₹${item.total}"),
              ),
            );
          }),

          const SizedBox(height: 20),

          Text(
            "Total: ₹${order.totalAmount}",

            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
