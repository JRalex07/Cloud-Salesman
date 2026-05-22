import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dashboard/screens/dashboard_screen.dart';

import '../screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // =========================
        // LOADING
        // =========================

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // =========================
        // LOGGED IN
        // =========================

        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // =========================
        // LOGIN
        // =========================

        return const LoginScreen();
      },
    );
  }
}
