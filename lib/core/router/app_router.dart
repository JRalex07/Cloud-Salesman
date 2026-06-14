import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';

// Import Screens in advance so references resolve
import 'package:cloud_power_salesman/features/auth/login_screen.dart';
import 'package:cloud_power_salesman/features/auth/forgot_password_screen.dart';
import 'package:cloud_power_salesman/features/dashboard/dashboard_screen.dart';
import 'package:cloud_power_salesman/features/shops/shop_list_screen.dart';
import 'package:cloud_power_salesman/features/shops/shop_detail_screen.dart';
import 'package:cloud_power_salesman/features/shops/add_edit_shop_screen.dart';
import 'package:cloud_power_salesman/features/visits/visit_screen.dart';
import 'package:cloud_power_salesman/features/orders/create_order_screen.dart';
import 'package:cloud_power_salesman/features/orders/cart_screen.dart';
import 'package:cloud_power_salesman/features/orders/order_history_screen.dart';
import 'package:cloud_power_salesman/features/orders/order_detail_screen.dart';
import 'package:cloud_power_salesman/features/attendance/attendance_screen.dart';
import 'package:cloud_power_salesman/features/profile/profile_screen.dart';
import 'package:cloud_power_salesman/features/notifications/notifications_screen.dart';
import 'package:cloud_power_salesman/features/dashboard/unknown_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    _subscription = ref.listen<AsyncValue<User?>>(authStateChangesProvider,
        (previous, next) {
      // Always notify when the auth state emits a new value,
      // even if it transitions from loading to null (logged out).
      notifyListeners();
    });
  }

  late final ProviderSubscription<AsyncValue<User?>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = AuthRefreshListenable(ref);
  ref.onDispose(() {
    listenable.dispose();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: listenable,
    errorBuilder: (context, state) => const UnknownPage(),
    // Dynamic redirect guard depending on Auth Session Status
    redirect: (context, state) {
      final authAsync = ref.read(authStateChangesProvider);

      // If the initial auth check is still in progress, don't redirect.
      // The custom builder in main.dart will show the splash screen.
      if (authAsync.isLoading) return null;

      final uid = authAsync.valueOrNull?.uid;
      final insideLogin = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';

      if (uid == null) {
        // If not logged in, force Login screen unless they are already trying to reset password
        return insideLogin ? null : '/login';
      }

      // If logged in, don't let them stay on login screen
      if (insideLogin) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Top-level direct deep link for Orders with literal 'ordID:' prefix
      GoRoute(
        path: '/order/:id',
        name: 'order-detail-direct',
        builder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      // Shell layout adding persistent sidebars for Wide Screen support
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationShellLayout(
              currentLocation: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/shops',
            name: 'shops',
            builder: (context, state) => const ShopListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'shop-add',
                builder: (context, state) => const AddEditShopScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'shop-detail',
                builder: (context, state) {
                  final shopId = state.pathParameters['id'] ?? '';
                  return ShopDetailScreen(shopId: shopId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/visits',
            name: 'visits',
            builder: (context, state) => const VisitScreen(),
          ),
          GoRoute(
            path: '/orders/create',
            name: 'order-create',
            builder: (context, state) {
              final shopId = state.uri.queryParameters['shopId'] ?? '';
              final shopName = state.uri.queryParameters['shopName'] ?? '';
              return CreateOrderScreen(shopId: shopId, shopName: shopName);
            },
          ),
          GoRoute(
            path: '/orders/cart',
            name: 'order-cart',
            builder: (context, state) {
              final shopId = state.uri.queryParameters['shopId'] ?? '';
              final shopName = state.uri.queryParameters['shopName'] ?? '';
              return CartScreen(shopId: shopId, shopName: shopName);
            },
          ),
          GoRoute(
            path: '/orders/history',
            name: 'order-history',
            builder: (context, state) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

// A wrapper adding unified visual Shell rails or Mobile navigation bars
class NavigationShellLayout extends ConsumerWidget {
  final String currentLocation;
  final Widget child;

  // Use a global key to open the slide-out drawer on mobile
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  const NavigationShellLayout({
    Key? key,
    required this.currentLocation,
    required this.child,
  }) : super(key: key);

  List<NavigationDestination> _getDestinations() {
    return const [
      NavigationDestination(
          icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      NavigationDestination(
          icon: Icon(Icons.storefront_outlined), label: 'Shops'),
      NavigationDestination(
          icon: Icon(Icons.directions_outlined), label: 'Visits'),
      NavigationDestination(
          icon: Icon(Icons.history_outlined), label: 'Orders'),
      NavigationDestination(
          icon: Icon(Icons.badge_outlined), label: 'Attendance'),
      NavigationDestination(
          icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];
  }

  List<NavigationDestination> _getMobileBottomDestinations() {
    return const [
      NavigationDestination(
          icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      NavigationDestination(
          icon: Icon(Icons.storefront_outlined), label: 'Shops'),
      NavigationDestination(
          icon: Icon(Icons.directions_outlined), label: 'Visits'),
      NavigationDestination(
          icon: Icon(Icons.history_outlined), label: 'Orders'),
      NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
    ];
  }

  int _getCurrentIndex() {
    if (currentLocation.startsWith('/shops')) return 1;
    if (currentLocation.startsWith('/visits')) return 2;
    if (currentLocation.startsWith('/orders')) return 3;
    if (currentLocation.startsWith('/attendance')) return 4;
    if (currentLocation.startsWith('/notifications')) return 5;
    if (currentLocation.startsWith('/profile')) return 6;
    return 0; // default to dashboard
  }

  int _getCurrentBottomIndex() {
    final int index = _getCurrentIndex();
    if (index >= 4) {
      return 4; // Map all drawer-only items (Attendance, Alerts, Profile) to the Menu tab
    }
    return index;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/shops');
        break;
      case 2:
        context.go('/visits');
        break;
      case 3:
        context.go('/orders/history');
        break;
      case 4:
        context.go('/attendance');
        break;
      case 5:
        context.go('/notifications');
        break;
      case 6:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double width = MediaQuery.of(context).size.width;

    // Responsive adaptation: Desktop Side Navigation Rail or Mobile Bottom Nav Bar with Drawer
    if (width >= 800) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: width >= 1200,
              selectedIndex: _getCurrentIndex(),
              onDestinationSelected: (value) => _onNavigate(context, value),
              leading: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cloud_upload, color: Colors.blue, size: 28),
                    ),
                    if (width >= 1200) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Cloud Power',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ]
                  ],
                ),
              ),
              destinations: _getDestinations().map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon ?? d.icon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    final salesmanProfile = ref.watch(salesmanProfileProvider).valueOrNull;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  salesmanProfile?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
              ),
              accountName: Text(
                salesmanProfile?.name ?? 'Sales Executive',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(
                '${salesmanProfile?.role ?? "Salesman"} • ${salesmanProfile?.assignedArea ?? "Unknown Area"}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    title: 'Dashboard',
                  ),
                  _buildDrawerItem(
                    context: context,
                    index: 1,
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront,
                    title: 'Shops',
                  ),
                  _buildDrawerItem(
                    context: context,
                    index: 2,
                    icon: Icons.directions_outlined,
                    activeIcon: Icons.directions,
                    title: 'Visits',
                  ),
                  _buildDrawerItem(
                    context: context,
                    index: 3,
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history,
                    title: 'Orders',
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context: context,
                    index: 4,
                    icon: Icons.badge_outlined,
                    activeIcon: Icons.badge,
                    title: 'Attendance',
                  ),
                  _buildDrawerItem(
                    context: context,
                    index: 5,
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    title: 'Alerts',
                  ),
                  _buildDrawerItem(
                    context: context,
                    index: 6,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: 'Profile',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Cloud Power v1.0',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getCurrentBottomIndex(),
        onDestinationSelected: (value) {
          if (value == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            _onNavigate(context, value);
          }
        },
        destinations: _getMobileBottomDestinations(),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final int currentIndex = _getCurrentIndex();
    final bool isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? Colors.blue : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.08),
      onTap: () {
        Navigator.pop(context); // Close the drawer first
        _onNavigate(context, index);
      },
    );
  }
}
