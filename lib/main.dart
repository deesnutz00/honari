import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // make sure this file exists
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main

  await Supabase.initialize(
    url: 'https://yriytuyeamxzcxyqtbgp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyaXl0dXllYW14emN4eXF0YmdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjM3NDgsImV4cCI6MjA2NzEzOTc0OH0.5Coq1Mhj1BMcDLJchHOjk35N8BASkU3NmHGqckPmWK4', // replace with your anon key
  );

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;

  runApp(HonariApp(seenOnboarding: seenOnboarding));
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
      ),
      home: seenOnboarding ? const LoginScreen() : const OnboardingScreen(),
    );
  }
}
