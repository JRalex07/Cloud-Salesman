import 'package:flutter/material.dart';

class SalesSummaryWidget extends StatelessWidget {
  const SalesSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Today's Sales",

            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),

          const SizedBox(height: 10),

          const Text(
            "₹12,540",

            style: TextStyle(
              color: Colors.white,

              fontSize: 34,

              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _summaryItem("Orders", "18")),

              Expanded(child: _summaryItem("Visits", "23")),

              Expanded(child: _summaryItem("Shops", "12")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,

          style: const TextStyle(
            color: Colors.white,

            fontSize: 20,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(title, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
