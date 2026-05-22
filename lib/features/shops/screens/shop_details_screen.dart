import 'package:flutter/material.dart';

import '../../../shared/models/shop_model.dart';

import '../../orders/screens/create_order_screen.dart';

import '../../visits/data/visit_repository.dart';

import '../../visits/widgets/checkin_button.dart';

import '../../visits/widgets/checkout_button.dart';

class ShopDetailsScreen extends StatelessWidget {
  final ShopModel shop;

  const ShopDetailsScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(shop.shopName)),

      body: StreamBuilder(
        stream: VisitRepository().activeVisit(),

        builder: (context, snapshot) {
          final activeVisit = snapshot.data;

          final isCurrentShopActive =
              activeVisit != null && activeVisit.shopId == shop.id;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =====================
                // SHOP CARD
                // =====================
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(20),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),

                        blurRadius: 10,

                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        shop.shopName,

                        style: const TextStyle(
                          fontSize: 28,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _item(Icons.person, "Owner", shop.ownerName),

                      _item(Icons.phone, "Phone", shop.phone),

                      _item(Icons.location_on, "Address", shop.address),

                      _item(
                        Icons.verified,
                        "Approved",
                        shop.approved ? "Yes" : "Pending",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =====================
                // CHECK IN
                // =====================
                if (!isCurrentShopActive)
                  CheckInButton(
                    onTap: () async {
                      try {
                        await VisitRepository().checkIn(
                          shopId: shop.id,

                          shopName: shop.shopName,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Checked in successfully"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                  ),

                // =====================
                // CHECK OUT
                // =====================
                if (isCurrentShopActive)
                  CheckOutButton(
                    onTap: () async {
                      try {
                        await VisitRepository().checkOut(activeVisit.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Checked out successfully"),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    },
                  ),

                const SizedBox(height: 16),

                // =====================
                // CREATE ORDER
                // =====================
                SizedBox(
                  width: double.infinity,

                  height: 56,

                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),

                    label: const Text("CREATE ORDER"),

                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => CreateOrderScreen(
                            shopId: shop.id,

                            shopName: shop.shopName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _item(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade700)),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
