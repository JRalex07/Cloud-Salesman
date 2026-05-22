import 'package:flutter/material.dart';

import '../data/order_repository.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = OrderRepository();

    return Scaffold(
      appBar: AppBar(title: const Text("Order History")),

      body: StreamBuilder(
        stream: repository.getOrders(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          return ListView.builder(
            itemCount: orders.length,

            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.all(12),

                child: ListTile(
                  leading: const Icon(Icons.receipt_long),

                  title: Text(order.shopName),

                  subtitle: Text("₹${order.totalAmount}"),

                  trailing: Text(order.status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
