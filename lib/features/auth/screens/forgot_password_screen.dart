import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';

import '../../../core/widgets/app_textfield.dart';

import '../../../shared/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final controller = TextEditingController();

  bool loading = false;

  Future<void> reset() async {
    setState(() {
      loading = true;
    });

    try {
      await ref.read(authServiceProvider).forgotPassword(controller.text);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reset email sent")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            AppTextField(controller: controller, hint: "Email"),

            const SizedBox(height: 20),

            AppButton(
              text: "SEND RESET EMAIL",

              loading: loading,

              onPressed: reset,
            ),
          ],
        ),
      ),
    );
  }
}
