import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/dashboard_card.dart';

import '../widgets/quick_action_button.dart';

import '../widgets/sales_summary_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width > 1200
        ? 4
        : width > 800
        ? 3
        : 2;

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ========================
            // SALES SUMMARY
            // ========================
            const SalesSummaryWidget(),

            const SizedBox(height: 24),

            // ========================
            // DASHBOARD CARDS
            // ========================
            GridView.count(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              crossAxisCount: crossAxisCount,

              crossAxisSpacing: 14,

              mainAxisSpacing: 14,

              childAspectRatio: 1.3,

              children: const [
                DashboardCard(
                  title: "Today's Orders",

                  value: "18",

                  icon: Icons.shopping_cart,

                  color: Colors.blue,
                ),

                DashboardCard(
                  title: "Shop Visits",

                  value: "23",

                  icon: Icons.store,

                  color: Colors.green,
                ),

                DashboardCard(
                  title: "Total Sales",

                  value: "₹12.5K",

                  icon: Icons.currency_rupee,

                  color: Colors.orange,
                ),

                DashboardCard(
                  title: "Commission",

                  value: "₹1,250",

                  icon: Icons.wallet,

                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              "Quick Actions",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              crossAxisCount: crossAxisCount,

              crossAxisSpacing: 14,

              mainAxisSpacing: 14,

              childAspectRatio: 1.1,

              children: [
                QuickActionButton(
                  title: "Add Shop",

                  icon: Icons.add_business,

                  onTap: () {
                    context.go("/add-shop");
                  },
                ),

                QuickActionButton(
                  title: "View Shops",

                  icon: Icons.storefront,

                  onTap: () {
                    context.go("/shops");
                  },
                ),

                QuickActionButton(
                  title: "Visit History",

                  icon: Icons.location_on,

                  onTap: () {
                    context.go("/visits");
                  },
                ),

                QuickActionButton(
                  title: "Products",

                  icon: Icons.inventory_2,

                  onTap: () {
                    context.go("/products");
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
