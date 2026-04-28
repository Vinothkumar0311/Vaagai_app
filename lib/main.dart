import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/firebase_options.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/course_provider.dart';
import 'package:vaagai/providers/course_access_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import 'package:vaagai/providers/notification_provider.dart';
import 'package:vaagai/providers/progress_provider.dart';
import 'package:vaagai/providers/cart_provider.dart';
import 'package:vaagai/providers/payment_provider.dart';
import 'package:vaagai/services/notification_service.dart';
import 'core/routes/app_routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler BEFORE runApp (required for low-end devices)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.initialize(navigatorKey);

  // Temporarily disabling App Check for debugging notifications
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider:
  //       kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  // );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => CourseAccessProvider()),
        ChangeNotifierProvider(create: (_) => DoubtProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Vaagai',
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: Colors.grey.shade900,
          child: Center(
            child: ClipRect(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
