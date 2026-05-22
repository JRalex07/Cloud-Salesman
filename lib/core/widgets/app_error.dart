import 'package:flutter/material.dart';

class AppError extends StatelessWidget {
  final String message;

  final VoidCallback? onRetry;

  const AppError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),

            const SizedBox(height: 16),

            Text(
              message,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
