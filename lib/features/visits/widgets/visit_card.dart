import 'package:flutter/material.dart';

import '../../shops/models/shop_visit_model.dart';

class VisitCard extends StatelessWidget {
  final ShopVisitModel visit;

  const VisitCard({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),

            blurRadius: 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.shopName,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: visit.active ? Colors.green : Colors.grey,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(
                  visit.active ? "ACTIVE" : "COMPLETED",

                  style: const TextStyle(
                    color: Colors.white,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text("Check In: ${visit.checkInTime}"),

          const SizedBox(height: 8),

          Text(
            visit.checkOutTime != null
                ? "Check Out: ${visit.checkOutTime}"
                : "Still Active",
          ),
        ],
      ),
    );
  }
}
