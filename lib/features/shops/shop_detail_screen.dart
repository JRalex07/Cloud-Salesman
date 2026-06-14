import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/core/widgets/custom_snackbar.dart';
import 'package:cloud_power_salesman/models/order.dart';
import 'package:cloud_power_salesman/models/shop.dart';
import 'package:cloud_power_salesman/models/visit.dart';
import 'package:cloud_power_salesman/repositories/shop_repository.dart';
import 'package:cloud_power_salesman/repositories/visit_repository.dart';
import 'package:cloud_power_salesman/repositories/order_repository.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({Key? key, required this.shopId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curSalesman = ref.watch(salesmanProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Summary'),
      ),
      body: FutureBuilder<Shop>(
        future: ref.read(shopRepositoryProvider).getShopById(shopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
                child:
                    Text('Failed to load store metadata: ${snapshot.error}'));
          }

          final shop = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopHeaderCard(context, shop),
                const SizedBox(height: 16),
                _buildWorkflowAccessPanel(
                    context, ref, shop, curSalesman?.uid ?? ''),
                const SizedBox(height: 24),
                _buildShopHistoryTabbedList(ref, shop.shopId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopHeaderCard(BuildContext context, Shop shop) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shop.imageUrl.isNotEmpty)
            Image.network(
              shop.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        shop.shopName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    Chip(
                      label: Text(shop.approved ? 'Approved' : 'Pending',
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          shop.approved ? Colors.green[50] : Colors.orange[50],
                      labelStyle: TextStyle(
                        color: shop.approved
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.person_outline, 'Shopkeeper', shop.shopkeeperName),
                _buildInfoRow(Icons.phone_outlined, 'Phone', shop.phone),
                _buildInfoRow(Icons.message_outlined, 'WhatsApp', shop.whatsapp,
                    isPhoneLink: true),
                _buildInfoRow(Icons.pin_drop_outlined, 'Address', shop.address),
                _buildInfoRow(Icons.map_outlined, 'Coordinates',
                    '${shop.latitude.toStringAsFixed(5)}, ${shop.longitude.toStringAsFixed(5)}'),
                if (shop.notes.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Owner Notes:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(shop.notes,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWorkflowAccessPanel(
    BuildContext context,
    WidgetRef ref,
    Shop shop,
    String salesmanId,
  ) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child:
                      const Icon(Icons.flash_on, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('Field Operations',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    icon: const Icon(Icons.login_outlined, size: 18),
                    label: const Text('Check In'),
                    onPressed: () async {
                      try {
                        final String uniqueVisitId =
                            'VST-${DateTime.now().millisecondsSinceEpoch}';
                        final visit = Visit(
                          visitId: uniqueVisitId,
                          shopId: shop.shopId,
                          shopName: shop.shopName,
                          checkInTime: DateTime.now(),
                          checkInLatitude: shop.latitude,
                          checkInLongitude: shop.longitude,
                          checkOutLatitude: 0.0,
                          checkOutLongitude: 0.0,
                          distanceFromShop: 0.0,
                          notes: '',
                          status: 'CheckedIn',
                          createdAt: DateTime.now(),
                        );
                        await ref
                            .read(visitRepositoryProvider)
                            .checkIn(salesmanId, visit);
                        if (context.mounted) {
                          CustomSnackbar.show(
                            context,
                            message: 'Session started for ${shop.shopName}',
                            type: SnackbarType.success,
                          );
                          context.go('/visits');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomSnackbar.show(
                            context,
                            message: 'Error: ${e.toString()}',
                            type: SnackbarType.error,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('New Order'),
                    onPressed: () {
                      context.go(
                          '/orders/create?shopId=${shop.shopId}&shopName=${Uri.encodeComponent(shop.shopName)}');
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShopHistoryTabbedList(WidgetRef ref, String shopId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Past Transaction Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Order>>(
          stream: ref.read(orderRepositoryProvider).getOrdersByShop(shopId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'No past orders booked at this outlet yet.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, idx) {
                final o = list[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text('Order ID: ${o.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '₹${o.total.toStringAsFixed(2)} • ${o.items.length} items ordered'),
                    trailing:
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                    onTap: () {
                      context.go('/order/${o.orderId}');
                    },
                  ),
                );
              },
            );
          },
        )
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isPhoneLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18, color: isPhoneLink ? Colors.blue : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '$label:',
                    style: TextStyle(
                        color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
