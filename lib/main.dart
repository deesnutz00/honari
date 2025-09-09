import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // make sure this file exists
import 'screens/dashboard_screen.dart'; // Add dashboard import
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main

  try {
    // Initialize Supabase with error handling
    await Supabase.initialize(
      url: 'https://yriytuyeamxzcxyqtbgp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4',
      debug: true, 
    );
  } catch (e) {
    // If Supabase fails to initialize, we'll still run the app
    // but without database functionality
    debugPrint('Supabase initialization failed: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    runApp(HonariApp(seenOnboarding: seenOnboarding));
  } catch (e) {
    // If SharedPreferences fails, run app with default onboarding
    debugPrint('SharedPreferences failed: $e');
    runApp(const HonariApp(seenOnboarding: false));
  }
}

class HonariApp extends StatefulWidget {
  final bool seenOnboarding;
  const HonariApp({super.key, required this.seenOnboarding});

  @override
  State<HonariApp> createState() => _HonariAppState();
}

class _HonariAppState extends State<HonariApp> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _setupAuthListener();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Check if user is already authenticated
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        _isAuthenticated = user != null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  void _setupAuthListener() {
    // Listen for authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final isAuthenticated = event.session != null;
      if (mounted) {
        setState(() {
          _isAuthenticated = isAuthenticated;
        });
      }
    });
  }

  Widget _getInitialScreen() {
    // If user hasn't seen onboarding, show onboarding first
    if (!widget.seenOnboarding) {
      return const OnboardingScreen();
    }

    // If user is authenticated, show dashboard
    if (_isAuthenticated) {
      return const DashboardScreen();
    }

    // Otherwise, show login screen
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF87CEEB)),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Honari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
      ),
      home: _getInitialScreen(),
    );
  }
}
