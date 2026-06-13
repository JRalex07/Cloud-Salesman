import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/models/order.dart';
import 'package:cloud_power_salesman/repositories/order_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curSalesman = ref.read(salesmanProfileProvider).valueOrNull;

    if (curSalesman == null) {
      return const Scaffold(
          body: Center(child: Text('Salesman profile offline.')));
    }

    final ordersStream =
        ref.watch(orderRepositoryProvider).getOrdersBySalesman(curSalesman.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booked Sales History'),
      ),
      body: StreamBuilder<List<Order>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 54, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No historical orders booked yet.',
                      style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/shops'),
                    child: const Text('Find Shops to Book Order'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, idx) {
              final o = list[idx];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.go('/order/${o.orderId}');
                    debugPrint('Tapped order ${o.orderId}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ID: ${o.orderId}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            _buildStatusChip(o.orderStatus),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Outlet Store:',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    o.shopName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Invoice Amount:',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${o.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Booked: ${o.createdAt.toLocal().toString().split(' ')[0]}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              'Payment: ${o.paymentStatus}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: o.paymentStatus == 'Paid'
                                    ? Colors.green[700]
                                    : Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = Colors.grey[100]!;
    Color text = Colors.grey[700]!;

    switch (status) {
      case 'Pending':
        bg = Colors.amber[50]!;
        text = Colors.amber[800]!;
        break;
      case 'Approved':
        bg = Colors.blue[50]!;
        text = Colors.blue[700]!;
        break;
      case 'Delivered':
        bg = Colors.green[50]!;
        text = Colors.green[800]!;
        break;
      case 'Cancelled':
        bg = Colors.red[50]!;
        text = Colors.red[700]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
