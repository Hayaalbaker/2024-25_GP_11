// signin_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_page.dart'; 
import 'register_screen.dart'; 
import 'reset_password.dart'; 

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscureText = true; 
  String? emailError; 
  String? passwordError; 

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (emailController.text.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      setState(() {
        emailError = 'Please enter a valid email.';
      });
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        passwordError = 'Please enter your password.';
      });
    }

    if (emailError != null || passwordError != null) {
      return; 
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
          emailError = 'Sign in failed. Please check your email, or password.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        emailError = e.toString(); 
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Center(
        child: SingleChildScrollView(
          child: isSmallScreen
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Logo(),
                    _FormContent(
                      emailController: emailController,
                      passwordController: passwordController,
                      emailError: emailError,
                      passwordError: passwordError,
                      isLoading: isLoading,
                      onLogin: _handleLogin,
                      onResetPassword: () {
                      Navigator.push(
                       context,
                        MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                       );
                      },         
                      obscureText: obscureText,
                      onTogglePasswordVisibility: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(32.0),
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    children: [
                      const Expanded(child: _Logo()),
                      Expanded(
                        child: Center(
                          child: _FormContent(
                            emailController: emailController,
                            passwordController: passwordController,
                            emailError: emailError,
                            passwordError: passwordError,
                            isLoading: isLoading,
                            onLogin: _handleLogin,
                            onResetPassword: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                               );
                            },
                            obscureText: obscureText,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'images/Logo.png', 
          width: 200, 
          height: 200, 
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Welcome to Localize!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ],
    );
  }
}

class _FormContent extends StatelessWidget {
  const _FormContent({
    required this.emailController,
    required this.passwordController,
    this.emailError,
    this.passwordError,
    required this.isLoading,
    required this.onLogin,
    required this.onResetPassword,
    required this.obscureText,
    required this.onTogglePasswordVisibility,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onResetPassword;
  final bool obscureText;
  final VoidCallback onTogglePasswordVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: emailError,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: obscureText,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: passwordError,
                suffixIcon: IconButton(
                  icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: onTogglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: onLogin,
                    child: const Text('Sign In'),
                  ),
            TextButton(
              onPressed: onResetPassword,
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