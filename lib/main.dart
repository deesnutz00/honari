import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // make sure this file exists
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main

  try {
    // Initialize Supabase with error handling
    await Supabase.initialize(
      url: 'https://yriytuyeamxzcxyqtbgp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4',
      debug: true, // Enable debug mode for better error messages
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

class HonariApp extends StatelessWidget {
  final bool seenOnboarding;
  const HonariApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
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
      home: seenOnboarding ? const LoginScreen() : const OnboardingScreen(),
    );
  }
}
