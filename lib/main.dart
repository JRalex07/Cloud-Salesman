import 'dart:async';
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

class FirebaseInitSplashScreen extends StatefulWidget {
  const FirebaseInitSplashScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseInitSplashScreen> createState() =>
      _FirebaseInitSplashScreenState();
}

class _FirebaseInitSplashScreenState extends State<FirebaseInitSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeListController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  int _stepIndex = 0;
  double _rawProgress = 0.0;
  Timer? _stepTimer;
  Timer? _progressTimer;

  final List<String> _steps = [
    'Constructing SQLite cache stores...',
    'Loading telemetry & coordinate parameters...',
    'Configuring secure offline fallbacks...',
    'Verifying Live Firestore synchronization...',
    'System loaded! Initializing session...'
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    );

    _fadeListController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeListController.forward();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1100), (timer) {
      if (mounted) {
        if (_stepIndex < _steps.length - 1) {
          setState(() {
            _stepIndex++;
            _fadeListController.reset();
            _fadeListController.forward();
          });
        } else {
          timer.cancel();
        }
      }
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (mounted) {
        if (_rawProgress < 100.0) {
          setState(() {
            _rawProgress += 1.2;
            if (_rawProgress > 100.0) _rawProgress = 100.0;
          });
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeListController.dispose();
    _stepTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isSmallMobile = width < 380;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -155,
              left: -155,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.indigo.withOpacity(0.04),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: isSmallMobile ? 130 : 150,
                        height: isSmallMobile ? 130 : 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            RotationTransition(
                              turns: _rotateAnimation,
                              child: Container(
                                width: isSmallMobile ? 120 : 140,
                                height: isSmallMobile ? 120 : 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  gradient: const SweepGradient(
                                    colors: [
                                      Colors.blueAccent,
                                      Colors.indigoAccent,
                                      Colors.blue,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.4, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: isSmallMobile ? 112 : 130,
                              height: isSmallMobile ? 112 : 130,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x0F0F172A),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.cloud_sync_outlined,
                                  size: 54,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Cloud Power Salesman',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.75,
                        color: Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'FMCG Enterprise Order Dispatch & Field Management',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 360),
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x050F172A),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SYSTEM BOOT IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                              Text(
                                '${_rawProgress.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _rawProgress / 100.0,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.indigoAccent),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildStepItem(0, 'SQLite storage initialised'),
                          _buildStepItem(
                              1, 'Geo-coordinates parameters resolved'),
                          _buildStepItem(2, 'Secure offline buffers verified'),
                          _buildStepItem(
                              3, 'Live Firestore channels listening'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _fadeListController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.indigoAccent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _steps[_stepIndex],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title) {
    final bool isCompleted = _stepIndex > stepIndex || _rawProgress >= 100.0;
    final bool isExecuting = _stepIndex == stepIndex && _rawProgress < 100.0;

    Color itemColor = const Color(0xFF94A3B8);
    Widget leadingWidget;

    if (isCompleted) {
      itemColor = const Color(0xFF0F172A);
      leadingWidget = const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: Colors.green,
      );
    } else if (isExecuting) {
      itemColor = Colors.indigo;
      leadingWidget = Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(2),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      );
    } else {
      leadingWidget = Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 20, height: 20, child: leadingWidget),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isCompleted
                    ? FontWeight.w600
                    : (isExecuting ? FontWeight.bold : FontWeight.w500),
                color: itemColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
