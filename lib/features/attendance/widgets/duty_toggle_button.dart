import 'package:flutter/material.dart';

class DutyToggleButton extends StatelessWidget {
  final bool active;

  final VoidCallback onTap;

  const DutyToggleButton({
    super.key,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 58,

      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? Colors.red : Colors.green,
        ),

        onPressed: onTap,

        icon: Icon(active ? Icons.logout : Icons.login),

        label: Text(active ? "END DUTY" : "START DUTY"),
      ),
    );
  }
}
