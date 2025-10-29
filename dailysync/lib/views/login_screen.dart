import 'dart:developer';

import 'package:dailysync/views/home_screen.dart';
import 'package:dailysync/views/signup_screen.dart';
import 'package:dailysync/widgets/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool _isLoading = false; // <-- ADDED: For loading indicator

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  
  // <-- ADDED: Created a separate login function for clarity
  Future<void> _loginUser() async {
    // 1. Validate fields first
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      CustomSnackbar().showCustomSnackbar(context, "Please fill all fields", bgColor: Colors.red);
      return; // Stop execution if fields are empty
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // 2. Attempt to sign in
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 3. THIS CODE RUNS ONLY ON SUCCESS
      if (userCredential.user != null) {
        log("Login Successful: ${userCredential.user!.uid}");
        CustomSnackbar().showCustomSnackbar(context, "Login Successful", bgColor: Colors.green);

        // Navigate to home screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      // 4. THIS CODE RUNS ONLY ON FAILURE
      log("Login Error: ${error.code} - ${error.message}");
      // Use a more descriptive error message
      CustomSnackbar().showCustomSnackbar(context, "Enter Valid Data", bgColor: Colors.red);
    } finally {
      // 5. Always stop loading, whether success or fail
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... your existing UI code (Title, TextFields, etc.)
              Text(
                '❇ DailySync',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blueGrey[900],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Syncing your Day, Your Way',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Email Field
              _buildTextField(
                controller: emailController,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // Password Field
              _buildTextField(
                controller: passwordController,
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                isObscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Login Button (MODIFIED)
              ElevatedButton(
                // Disable button while loading, call the new login function
                onPressed: _isLoading ? null : _loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blueGrey[700] : const Color(0xFF5D9CEC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox( // Show a spinner when loading
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 30),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 15),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign Up',
                        style: const TextStyle(color: Color(0xFF5D9CEC), fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignUpScreen()),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // No changes to _buildTextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[400]),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? Colors.white70 : Colors.grey[600]) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5D9CEC)),
        ),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
    );
  }
}