import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:dailysync/views/login_screen.dart'; 
import 'package:dailysync/widgets/custom_snackbar.dart'; 

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController(); 
  final dobController = TextEditingController(); 
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  DateTime? _selectedDate; 

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose(); 
    dobController.dispose(); 
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool validateFields() {
   
    if ([
      nameController,
      emailController,
      phoneController,
      dobController,
      passwordController,
      confirmPasswordController
    ].any((ctrl) => ctrl.text.trim().isEmpty)) {
      CustomSnackbar()
          .showCustomSnackbar(context, "Please fill all fields", bgColor: Colors.red);
      return false;
    }

    final emailPattern = r'^[^@]+@[^@]+\.[^@]+';
    if (!RegExp(emailPattern).hasMatch(emailController.text)) {
      CustomSnackbar()
          .showCustomSnackbar(context, "Enter a valid email address", bgColor: Colors.red);
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      CustomSnackbar()
          .showCustomSnackbar(context, "Passwords do not match", bgColor: Colors.red);
      return false;
    }

    return true;
  }

 
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900), 
      lastDate: DateTime.now(), 
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        
        dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveUserDetailsToFirestore(User user) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final userData = {
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'dob': dobController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), 
      };

      
      await firestore.collection('users').doc(user.uid).set(userData);

      log("User details saved to Firestore successfully.");
    } catch (e) {
      log("Error saving user details to Firestore: $e");
      // Show an error snackbar if saving details fails
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Error: Could not save your details.",
          bgColor: Colors.red,
        );
      }
    }
  }


  Future<void> registerUser() async {
    if (!validateFields()) return;

    setState(() => isLoading = true);

    

    if (mounted) {
      try {
        UserCredential userCredentialobj =
            await _firebaseAuth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        log("User Credentials: $userCredentialobj");

      
        final User? user = userCredentialobj.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'null-user',
            message: 'User creation returned null.',
          );
        }

       
        await user.updateProfile(displayName: nameController.text.trim());

       
        await _saveUserDetailsToFirestore(user);

        CustomSnackbar()
            .showCustomSnackbar(context, "Registered Successfully", bgColor: Colors.green);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (error) {
        
        log("Error Code:${error.code}");
        log("Error Message: ${error.message}");
        if (error.code.toString() == "invalid-email") {
          CustomSnackbar()
              .showCustomSnackbar(context, "Enter Valid Email id", bgColor: Colors.red);
        } else {
          CustomSnackbar()
              .showCustomSnackbar(context, error.message!, bgColor: Colors.red);
        }
      } catch (e) {
       
        log("Generic Error: $e");
        CustomSnackbar().showCustomSnackbar(
            context, "An unexpected error occurred. Please try again.",
            bgColor: Colors.red);
      } finally {
        
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'DailySync: Sync Your Day, Your Way.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField('Full Name', nameController, 'Enter your full name'),
              const SizedBox(height: 20),
              _buildTextField('Email', emailController, 'your.email@example.com',
                  keyboardType: TextInputType.emailAddress),
              
             
              const SizedBox(height: 20),
              _buildTextField('Phone Number', phoneController, 'Enter your phone number',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildTextField('Date of Birth', dobController, 'Select your DOB',
                  readOnly: true, 
                  onTap: () => _selectDate(context), 
                  suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[600])),
              

              const SizedBox(height: 20),
              _buildTextField('Password', passwordController, 'Create a strong password',
                  isObscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )),
              const SizedBox(height: 20),
              _buildTextField('Confirm Password', confirmPasswordController, 'Confirm your password',
                  isObscure: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  )),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),

              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 15),
                    children: [
                      const TextSpan(text: "Already have an account? "),
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                            color: Color(0xFF5D9CEC), fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
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

 
  // Widget _buildTextField(String label, TextEditingController controller, String hintText,
  //     {bool isObscure = false,
  //     Widget? suffixIcon,
  //     TextInputType keyboardType = TextInputType.text,
  //     bool readOnly = false, 
  //     VoidCallback? onTap    
  //     }) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(label,
  //           style: TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: Theme.of(context).colorScheme.onBackground)),
  //       const SizedBox(height: 8),
  //       TextField(
  //         controller: controller,
  //         obscureText: isObscure,
  //         keyboardType: keyboardType,
  //         readOnly: readOnly, 
  //         decoration: InputDecoration(
  //           hintText: hintText,
  //           hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[400]),
  //           contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
  //           suffixIcon: suffixIcon,
  //           filled: true,
  //           fillColor: isDark ? Colors.grey[850] : Colors.white,
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8.0),
  //             borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8.0),
  //             borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
  //           ),
  //         ),
  //         style: TextStyle(color: isDark ? Colors.white : Colors.black87),
  //       ),
  //     ],
  //   );
  // }


  // [MODIFIED FILE: lib/view/signup_screen.dart]

// ... (previous code)

  Widget _buildTextField(String label, TextEditingController controller, String hintText,
      {bool isObscure = false,
      Widget? suffixIcon,
      TextInputType keyboardType = TextInputType.text,
      bool readOnly = false, 
      VoidCallback? onTap    // <--- onTap parameter defined
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          readOnly: readOnly, 
          onTap: onTap, // <--- ADD THIS LINE: Pass the onTap callback to the TextField
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? Colors.grey[850] : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ],
    );
  }
}


