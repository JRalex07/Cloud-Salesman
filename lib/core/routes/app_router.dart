import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../features/attendance/screens/attendance_screen.dart';

import '../../features/auth/screens/forgot_password_screen.dart';

import '../../features/auth/screens/login_screen.dart';

import '../../features/dashboard/screens/dashboard_screen.dart';

import '../../features/notifications/screens/notifications_screen.dart';

import '../../features/orders/screens/order_history_screen.dart';

import '../../features/products/screens/products_screen.dart';

import '../../features/profile/screens/profile_screen.dart';

import '../../features/shops/screens/add_shop_screen.dart';

import '../../features/shops/screens/shops_screen.dart';

import '../../features/visits/screens/active_visit_screen.dart';

import '../../features/visits/screens/visit_history_screen.dart';

import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: "/",

    debugLogDiagnostics: true,

    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),

    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;

      final isAuthRoute =
          state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.forgotPassword;

      // NOT LOGGED IN

      if (!loggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      // LOGGED IN

      if (loggedIn && isAuthRoute) {
        return RouteNames.dashboard;
      }

      return null;
    },

    routes: [
      // =========================
      // ROOT
      // =========================
      GoRoute(
        path: "/",

        redirect: (context, state) {
          final loggedIn = FirebaseAuth.instance.currentUser != null;

          if (loggedIn) {
            return RouteNames.dashboard;
          }

          return RouteNames.login;
        },
      ),

      // =========================
      // LOGIN
      // =========================
      GoRoute(
        path: RouteNames.login,

        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      // =========================
      // FORGOT PASSWORD
      // =========================
      GoRoute(
        path: RouteNames.forgotPassword,

        builder: (context, state) {
          return const ForgotPasswordScreen();
        },
      ),

      // =========================
      // APP SHELL
      // =========================
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(child: child);
        },

        routes: [
          // DASHBOARD
          GoRoute(
            path: RouteNames.dashboard,

            builder: (context, state) {
              return const DashboardScreen();
            },
          ),

          // PRODUCTS
          GoRoute(
            path: RouteNames.products,

            builder: (context, state) {
              return const ProductsScreen();
            },
          ),

          // SHOPS
          GoRoute(
            path: RouteNames.shops,

            builder: (context, state) {
              return const ShopsScreen();
            },
          ),

          // ADD SHOP
          GoRoute(
            path: RouteNames.addShop,

            builder: (context, state) {
              return const AddShopScreen();
            },
          ),

          // VISITS
          GoRoute(
            path: RouteNames.visits,

            builder: (context, state) {
              return const VisitHistoryScreen();
            },
          ),

          // ACTIVE VISIT
          GoRoute(
            path: RouteNames.activeVisit,

            builder: (context, state) {
              return const ActiveVisitScreen();
            },
          ),

          // ORDERS
          GoRoute(
            path: RouteNames.orders,

            builder: (context, state) {
              return const OrderHistoryScreen();
            },
          ),

          // ATTENDANCE
          GoRoute(
            path: RouteNames.attendance,

            builder: (context, state) {
              return const AttendanceScreen();
            },
          ),

          // NOTIFICATIONS
          GoRoute(
            path: RouteNames.notifications,

            builder: (context, state) {
              return const NotificationsScreen();
            },
          ),

          // PROFILE
          GoRoute(
            path: RouteNames.profile,

            builder: (context, state) {
              return const ProfileScreen();
            },
          ),
        ],
      ),
    ],
  );
}

// =========================================
// ROUTER REFRESH LISTENER
// =========================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();

    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();

    super.dispose();
  }
}

// =========================================
// DASHBOARD SHELL
// =========================================

class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  int _index(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location == RouteNames.products) {
      return 1;
    }

    if (location == RouteNames.shops) {
      return 2;
    }

    if (location == RouteNames.orders) {
      return 3;
    }

    if (location == RouteNames.profile) {
      return 4;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _index(context);

    return Scaffold(
      body: child,

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RouteNames.dashboard);
              break;

            case 1:
              context.go(RouteNames.products);
              break;

            case 2:
              context.go(RouteNames.shops);
              break;

            case 3:
              context.go(RouteNames.orders);
              break;

            case 4:
              context.go(RouteNames.profile);
              break;
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),

            label: "Dashboard",
          ),

          NavigationDestination(
            icon: Icon(Icons.inventory_2),

            label: "Products",
          ),

          NavigationDestination(icon: Icon(Icons.store), label: "Shops"),

          NavigationDestination(
            icon: Icon(Icons.shopping_cart),

            label: "Orders",
          ),

          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
