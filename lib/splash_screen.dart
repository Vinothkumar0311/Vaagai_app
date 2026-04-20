import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/core/utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _splashDelay = Duration(seconds: 3);
  static const _pollDelay = Duration(milliseconds: 100);
  static const _maxLoadingWaitMs = 5000;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(_splashDelay);
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    var hasValidSession = await SessionManager.isSessionValid();

    if (!mounted) return;

    // If user is logged in Firebase Auth but session data is missing (after cache clear),
    // restore the session instead of logging them out
    if (authProvider.isLoggedIn && !hasValidSession) {
      await SessionManager.saveSession();
      hasValidSession = true;
    }

    // Wait for user details to be fetched if still loading
    // (important for cache-cleared scenarios or slow network)
    var maxWaitTime = 0;
    while (authProvider.isLoading && maxWaitTime < _maxLoadingWaitMs) {
      await Future.delayed(_pollDelay);
      maxWaitTime += _pollDelay.inMilliseconds;
      if (!mounted) return;
    }

    if (!mounted) return;

    // Navigate based on authentication status
    // If user is logged in with valid session, go to dashboard
    // (userModel will be populated after user details are fetched)
    if (authProvider.isLoggedIn && hasValidSession) {
      navigator.pushReplacementNamed(AppRoutes.dashboard);
    } else {
      navigator.pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 300,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 100, color: Colors.green),
            ),
          ),
        ),
      ),
    );
  }
}
