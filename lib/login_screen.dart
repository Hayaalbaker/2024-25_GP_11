import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase User
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                User? user = await _authService.signInWithEmailAndPassword(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );

                if (mounted) { // Check if the widget is still mounted
                  if (user != null) {
                    print('Signed in: ${user.email}');
                    // Navigate to another screen on successful login
                    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                  } else {
                    // Show Snackbar with error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign in failed. Please check your credentials.')),
                    );
                  }
                }
              },
              child: const Text('Login'),
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

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: userNameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User? user = await _authService.registerWithEmailAndPassword(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );

                  if (mounted) { // Check if the widget is still mounted
                    if (user != null) {
                      print('Registered successfully');
                      Navigator.pop(context);
                    } else {
                      print('Registration failed');
                      // Show Snackbar with error message if needed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registration failed. Please try again.')),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}