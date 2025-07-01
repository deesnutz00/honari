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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
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

              // Fields
              const _GreyTextField(
                icon: Icons.person_outline,
                hintText: 'Full name',
              ),
              const SizedBox(height: 16),
              const _GreyTextField(
                icon: Icons.email_outlined,
                hintText: 'Email address',
              ),
              const SizedBox(height: 16),
              const _GreyTextField(
                icon: Icons.lock_outline,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const _GreyTextField(
                icon: Icons.lock_outline,
                hintText: 'Confirm password',
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Add sign-up logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF87CEEB), // sky blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or', style: TextStyle(color: Colors.grey)),
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
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color.fromARGB(
                        255,
                        135,
                        206,
                        235,
                      ), // Outline color
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue with Google',
                    style: TextStyle(color: Color.fromARGB(255, 135, 206, 235)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to login
                  },
                  child: const Text(
                    "Already have an account? Sign in",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TextField with login-style grey background
class _GreyTextField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool obscureText;

  const _GreyTextField({
    Key? key,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF1F1F1), // Light grey background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
