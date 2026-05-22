import 'package:flutter/material.dart';

class CheckOutButton extends StatelessWidget {
  final VoidCallback onTap;

  const CheckOutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 56,

      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

        onPressed: onTap,

        icon: const Icon(Icons.logout),

        label: const Text("CHECK OUT"),
      ),
    );
  }
}
