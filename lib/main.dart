import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // make sure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main
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
