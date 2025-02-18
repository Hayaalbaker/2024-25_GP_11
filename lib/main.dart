import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Map<String, dynamic>>> sendUserIdToServer() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint("❌ No user is logged in!");
    return [];
  }

  final String userId = user.uid;
  final String apiUrl = 'http://10.0.2.2:5000/api/receiveUserId';

  try {
    debugPrint("📡 Sending request to: $apiUrl");
    debugPrint("📤 Request data: ${jsonEncode({'userId': userId})}");

    final response = await http
        .post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json", "Connection": "close"},
      body: jsonEncode({'userId': userId}),
    )
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException("⏳ Server did not respond in time.");
    });

    debugPrint("📥 Server response (Status Code): ${response.statusCode}");
    debugPrint("📥 Raw Response content: ${response.body}");

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse.containsKey('recommendations')) {
        debugPrint("✅ Retrieved places inside 'recommendations'.");
        return List<Map<String, dynamic>>.from(jsonResponse['recommendations']);
      } else {
        debugPrint("⚠️ Unexpected JSON format: $jsonResponse");
      }
    } else {
      debugPrint(
          "❌ Failed to fetch data, response code: ${response.statusCode}");
    }
  } on TimeoutException {
    debugPrint("❌ Connection timeout! Server is not responding.");
  } on FormatException {
    debugPrint("❌ FormatException: Invalid JSON response.");
  } catch (e) {
    debugPrint("❌ Unexpected error while connecting to the server: $e");
  }

  return [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    //  name: "Localize",
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
      home: OnboardingPage1(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return WelcomeScreen();
          } else {
            return HomePage();
          }
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
