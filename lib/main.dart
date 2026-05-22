import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

import 'firebase_options.dart';

import 'core/routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CLEAN WEB URLS
  usePathUrlStrategy();

  // FIREBASE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: "Cloud Power Salesman",

      routerConfig: AppRouter.router,

      theme: ThemeData(useMaterial3: true, fontFamily: "NotoSans"),
    );
  }
}
