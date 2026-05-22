import 'package:flutter/material.dart';

import '../../../shared/models/order_model.dart';

import 'quantity_selector.dart';

class CartItemTile extends StatelessWidget {
  final OrderItemModel item;

  final VoidCallback onAdd;

  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    item.productName,

                    style: const TextStyle(
                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text("₹${item.price}"),

                  const SizedBox(height: 6),

                  Text("Total: ₹${item.total}"),
                ],
              ),
            ),

            QuantitySelector(
              quantity: item.quantity,

              onAdd: onAdd,

              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
