import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:cloud_power_salesman/firebase_options.dart';
import 'package:cloud_power_salesman/providers/global_providers.dart';
import 'package:cloud_power_salesman/core/router/app_router.dart';
import 'package:cloud_power_salesman/core/theme/app_theme.dart';

// Top-level background message message handler required for Firebase Cloud Messaging (FCM)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

void main() async {
  // Ensure framework services are initialized before async boots
  WidgetsFlutterBinding.ensureInitialized();
  
  // Clean up Web URL strategy (removes the # from URL)
  // This must be called BEFORE any navigation happens.
  usePathUrlStrategy();

  // Robust initialization of Firebase services BEFORE runApp
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background messaging handler for Mobile
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }

  runApp(
    // Riverpod ProviderScope managing global state containers
    const ProviderScope(
      child: CloudPowerSalesmanApp(),
    ),
  );
}

class CloudPowerSalesmanApp extends ConsumerWidget {
  const CloudPowerSalesmanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // GoRouter instance is kept stable by the Provider
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cloud Power Salesman',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Consistent high-contrast light theme as per guidelines
      routerConfig: goRouter,
      // The builder is the key to showing the splash screen without breaking routing.
      // GoRouter stays active and maintains the URL, while we render our Splash UI.
      builder: (context, child) {
        final authAsync = ref.watch(authStateChangesProvider);
        
        // While auth state is being determined (loading from persistence), show splash
        if (authAsync.isLoading) {
          return const FirebaseInitSplashScreen();
        }
        
        // Once auth is ready, show the matched route (child)
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class FirebaseInitSplashScreen extends StatelessWidget {
  const FirebaseInitSplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cloud Power Salesman',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Restoring secure session...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
