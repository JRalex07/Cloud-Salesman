import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../models/order_timeline.dart';
import '../../providers/global_providers.dart';
import '../../repositories/order_repository.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderRepo = ref.read(orderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary Details'),
      ),
      body: StreamBuilder<List<Order>>(
        // Listen to all salesman orders, but narrow down to the custom ID structure
        stream: ref.watch(orderRepositoryProvider).getOrdersBySalesman(
              ref.watch(salesmanProfileProvider).valueOrNull?.uid ?? '',
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          final oMatches = list.where((ord) => ord.orderId == orderId).toList();
          if (oMatches.isEmpty) {
            return const Center(
                child: Text('Sales order details not found or inaccessible.'));
          }

          final Order order = oMatches.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryBox(order),
                const SizedBox(height: 20),
                const Text('Items Ordered List',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildItemsList(order),
                const SizedBox(height: 24),
                const Text('Fulfillment Tracking Logs',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildTimelineStepper(ref, order.orderId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBox(Order o) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Booking ID:',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(o.orderId,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(o.orderStatus,
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Client Store Name:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(o.shopName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date Booked:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(o.createdAt.toLocal().toString().split('.')[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Payment Collection Status:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text(o.paymentStatus,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green)),
              ],
            ),
            if (o.notes.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Assigned Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(o.notes,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 13)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(Order o) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: o.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final item = o.items[idx];
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                          'Qty: ${item.quantity}  •  Rate: ₹${item.price.toStringAsFixed(2)}  •  GST: ${item.gstPercentage}%',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                Text('₹${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStepper(WidgetRef ref, String oId) {
    final future = ref.read(orderRepositoryProvider).getOrderTimeline(oId);

    return FutureBuilder<List<OrderTimeline>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final timeline = snapshot.data ?? [];
        if (timeline.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('No tracking event logs registered yet.',
                    style: TextStyle(color: Colors.grey[500])),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, idx) {
                final log = timeline[idx];
                final isLast = idx == timeline.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Icon(Icons.check_circle_outline,
                              color: Theme.of(context).primaryColor, size: 16),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: Colors.blue[100],
                          )
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(log.status,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(
                                log.timestamp
                                    .toLocal()
                                    .toString()
                                    .split(' ')[1]
                                    .substring(0, 5),
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(log.message,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Updated by ID: ${log.updatedBy}',
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
