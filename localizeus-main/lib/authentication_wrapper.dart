import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';
import 'home_page.dart'; 

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignInScreen(); // User is not logged in
          } else {
            return HomePage(); // User is logged in
          }
        }

        // Loading state
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}