import 'package:flutter/material.dart';

import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  const SizedBox(height: 40),

                  const Icon(Icons.storefront, size: 80),

                  const SizedBox(height: 20),

                  const Text(
                    "Cloud Power Salesman",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text("Login to continue", textAlign: TextAlign.center),

                  const SizedBox(height: 40),

                  const LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
