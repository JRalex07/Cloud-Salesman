import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_button.dart';

import '../../../core/widgets/app_textfield.dart';

import '../../../core/utils/validators.dart';

import '../../../shared/providers/auth_provider.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await ref
          .read(authServiceProvider)
          .signIn(
            email: emailController.text,
            password: passwordController.text,
          );
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
    return Form(
      key: _formKey,

      child: Column(
        children: [
          AppTextField(
            controller: emailController,

            hint: "Email",

            keyboardType: TextInputType.emailAddress,

            validator: Validators.email,
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: passwordController,

            hint: "Password",

            obscureText: true,

            validator: Validators.password,
          ),

          const SizedBox(height: 24),

          AppButton(text: "LOGIN", loading: loading, onPressed: login),
        ],
      ),
    );
  }
}
