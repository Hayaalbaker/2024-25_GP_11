// signin_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_page.dart'; // Ensure the correct filename is used
import 'register_screen.dart'; // Import RegisterScreen

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscureText = true; // For show/hide password functionality
  String? emailError; // Error message for email
  String? passwordError; // Error message for password

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (emailController.text.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.sendPasswordResetEmail(email: emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    // Reset all error messages
    setState(() {
      emailError = null;
      passwordError = null;
    });

    // Validate email
    if (emailController.text.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      setState(() {
        emailError = 'Please enter a valid email.';
      });
    }

    // Validate password
    if (passwordController.text.length < 6) {
      setState(() {
        passwordError = 'Password must be at least 6 characters long.';
      });
    }

    // Check if there are any errors
    if (emailError != null || passwordError != null) {
      return; // Exit if there are errors
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? user = await _authService.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        setState(() {
          emailError = 'Log in failed. Please check your credentials.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        emailError = e.toString(); // Update error message
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Prevent overflow on smaller screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError, // Show error message here
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError, // Show error message here
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Login Button
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
              // Forgot Password Button
              TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot Password?'),
              ),
              // Register Button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}