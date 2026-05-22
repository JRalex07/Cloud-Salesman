import 'package:flutter/material.dart';

class OrderSummary extends StatelessWidget {
  final double total;

  final VoidCallback onSubmit;

  const OrderSummary({super.key, required this.total, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text("Total Amount"),

                const SizedBox(height: 6),

                Text(
                  "₹${total.toStringAsFixed(2)}",

                  style: const TextStyle(
                    fontSize: 24,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ElevatedButton(onPressed: onSubmit, child: const Text("PLACE ORDER")),
        ],
      ),
    );
  }
}
