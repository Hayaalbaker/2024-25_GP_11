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
  String? _errorMessage; // Variable to hold error messages

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
          SnackBar(content: Text('Please enter a valid email.')));
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(emailController.text.trim());
      if (mounted) { // Check if the widget is still in the widget tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent.'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _errorMessage, // Show error message here
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              obscureText: obscureText,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _errorMessage, // Show error message here
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
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      // Validate email
                      if (emailController.text.isEmpty ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(emailController.text)) {
                        setState(() {
                          _errorMessage = 'Please enter a valid email.';
                        });
                        return;
                      }

                      // Validate password
                      if (passwordController.text.length < 6) {
                        setState(() {
                          _errorMessage =
                              'Password must be at least 6 characters long.';
                        });
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        _errorMessage = null; // Reset error message
                      });

                      try {
                        User? user = await _authService.signInWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );

                        if (mounted) { // Guarding the use of context
                          if (user != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomePage()),
                            );
                          } else {
                            setState(() {
                              _errorMessage =
                                  'Log in failed. Please check your credentials.';
                            });
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = e.toString(); // Update error message
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    child: const Text('Login'),
                  ),
            TextButton(
              onPressed: _resetPassword,
              child: const Text('Forgot Password?'),
            ),
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
    );
  }
}