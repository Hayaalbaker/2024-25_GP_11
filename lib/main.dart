// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'welcome_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localize',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: AuthenticationWrapper(), // Use AuthenticationWrapper for navigation
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final AuthService _authService = AuthService(); // Instantiate AuthService

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges, // Use AuthService's authStateChanges
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return WelcomeScreen(); // Navigate to WelcomeScreen if not logged in
          } else {
            return HomePage(); // Navigate to HomePage if logged in
          }
        }

        // While checking the auth state, show a loading indicator
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}