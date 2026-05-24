import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Top-level background message message handler required for Firebase Cloud Messaging (FCM)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
}

void main() async {
  // Ensure framework services are initialized before async boots
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  runApp(
    // Riverpod ProviderScope managing global state containers
    const ProviderScope(
      child: CloudPowerSalesmanApp(),
    ),
  );
}

class CloudPowerSalesmanApp extends ConsumerStatefulWidget {
  const CloudPowerSalesmanApp({Key? key}) : super(key: key);

  @override
  ConsumerState<CloudPowerSalesmanApp> createState() =>
      _CloudPowerSalesmanAppState();
}

class _CloudPowerSalesmanAppState extends ConsumerState<CloudPowerSalesmanApp> {
  late Future<void> _firebaseInitFuture;

  @override
  void initState() {
    super.initState();
    _firebaseInitFuture = _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      // Always attempt standard platform-default initialization first
      // (This will automatically read and load google-services.json on Android / iOS)
      try {
        await Firebase.initializeApp();
      } catch (e) {
        if (kDebugMode) {
          print(
              'Default Firebase initialization failed, trying platform fallback presets: $e');
        }
        // If default initialization fails, utilize progressive offline sandboxed presets
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "dummy-api-key-for-progressive-offline",
              appId: "1:1234567890:web:1234567890abcdef",
              messagingSenderId: "1234567890",
              projectId: "cloud-power-salesman-offline",
              authDomain: "cloud-power-salesman-offline.firebaseapp.com",
              storageBucket: "cloud-power-salesman-offline.appspot.com",
            ),
          );
        } else {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "dummy-api-key-for-progressive-offline",
              appId: "1:1234567890:android:1234567890abcdef",
              messagingSenderId: "1234567890",
              projectId: "cloud-power-salesman-offline",
            ),
          );
        }
      }

      // Register background handlers
      if (!kIsWeb) {
        try {
          FirebaseMessaging.onBackgroundMessage(
              _firebaseMessagingBackgroundHandler);
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Firebase failed to initialize. Running in progressive offline fallback mode: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInitFuture,
      builder: (context, snapshot) {
        // Render high-polish Splash screen during initialization (waiting or active but not done)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'Cloud Power Salesman',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const FirebaseInitSplashScreen(),
          );
        }

        // Once completed, safely watch/render GoRouter config
        final goRouter = ref.watch(routerProvider);

        return MaterialApp.router(
          title: 'Cloud Power Salesman',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode
              .light, // Default to clean High Contrast Light Theme as per guidelines
          routerConfig: goRouter,
        );
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
              'Initializing secure services and local databases...',
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
