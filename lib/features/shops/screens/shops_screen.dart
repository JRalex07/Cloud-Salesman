import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_provider.dart';

import '../widgets/shop_card.dart';

import 'shop_details_screen.dart';

class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(shopRepositoryProvider);

    final width = MediaQuery.of(context).size.width;

    final horizontalPadding = width > 900 ? 40.0 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text("My Shops")),

      body: StreamBuilder(
        stream: repository.getShops(),

        builder: (context, snapshot) {
          // =====================
          // LOADING
          // =====================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // =====================
          // ERROR
          // =====================

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final shops = snapshot.data ?? [];

          // =====================
          // EMPTY
          // =====================

          if (shops.isEmpty) {
            return const Center(child: Text("No shops added yet"));
          }

          // =====================
          // SHOPS
          // =====================

          return RefreshIndicator(
            onRefresh: () async {},

            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,

                vertical: 12,
              ),

              itemCount: shops.length,

              itemBuilder: (context, index) {
                final shop = shops[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),

                  child: ShopCard(
                    shop: shop,

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => ShopDetailsScreen(shop: shop),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
