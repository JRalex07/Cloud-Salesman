import 'package:flutter/material.dart';

enum SnackbarType { success, error, info, warning }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    IconData icon;
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color borderColor;

    switch (type) {
      case SnackbarType.success:
        icon = Icons.check_circle_outline;
        backgroundColor = const Color(0xFFE8F5E9); // Light Green
        textColor = const Color(0xFF2E7D32); // Dark Green
        iconColor = const Color(0xFF2E7D32);
        borderColor = const Color(0xFFA5D6A7);
        break;
      case SnackbarType.error:
        icon = Icons.error_outline;
        backgroundColor = const Color(0xFFFFEBEE); // Light Red
        textColor = const Color(0xFFC62828); // Dark Red
        iconColor = const Color(0xFFC62828);
        borderColor = const Color(0xFFEF9A9A);
        break;
      case SnackbarType.warning:
        icon = Icons.warning_amber_outlined;
        backgroundColor = const Color(0xFFFFF8E1); // Light Amber
        textColor = const Color(0xFFF57F17); // Dark Amber
        iconColor = const Color(0xFFF57F17);
        borderColor = const Color(0xFFFFE082);
        break;
      case SnackbarType.info:
        icon = Icons.info_outline;
        backgroundColor = const Color(0xFFE3F2FD); // Light Blue
        textColor = const Color(0xFF1565C0); // Dark Blue
        iconColor = const Color(0xFF1565C0);
        borderColor = const Color(0xFF90CAF9);
        break;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
