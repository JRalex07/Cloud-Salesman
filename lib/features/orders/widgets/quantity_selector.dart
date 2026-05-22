import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;

  final VoidCallback onAdd;

  final VoidCallback onRemove;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_circle)),

        Text(
          quantity.toString(),

          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle)),
      ],
    );
  }
}
