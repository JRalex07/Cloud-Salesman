import 'package:flutter/material.dart';

class CheckInButton extends StatelessWidget {
  final VoidCallback onTap;

  const CheckInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 56,

      child: ElevatedButton.icon(
        onPressed: onTap,

        icon: const Icon(Icons.login),

        label: const Text("CHECK IN"),
      ),
    );
  }
}
