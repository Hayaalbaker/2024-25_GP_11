import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 20),
              Text("Admin Login", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              TextField(decoration: InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(obscureText: true, decoration: InputDecoration(labelText: "Password")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text("Sign In"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}