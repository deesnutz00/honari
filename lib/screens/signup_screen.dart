import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_back),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: const [
                    Text(
                      'Honari 本',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF87CEEB), // sky blue
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your free account',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const _SoftTextField(
                icon: Icons.person_outline,
                hintText: 'Full name',
              ),
              const SizedBox(height: 16),
              const _SoftTextField(
                icon: Icons.email_outlined,
                hintText: 'Email address',
              ),
              const SizedBox(height: 16),
              const _SoftTextField(
                icon: Icons.lock_outline,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const _SoftTextField(
                icon: Icons.lock_outline,
                hintText: 'Confirm password',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Add sign-up logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF87CEEB), // sky blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.grey.withOpacity(0.2),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Color(0xFFE8D0D0),
                    ), // sakura soft pink
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to login
                  },
                  child: const Text("Already have an account? Sign in"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Soft Text Field Widget
class _SoftTextField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool obscureText;

  const _SoftTextField({
    Key? key,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        filled: true,
        fillColor: Color(0xFFFDF6F6), // very soft sakura tone
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
