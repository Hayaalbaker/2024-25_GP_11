import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'package:flutter/material.dart';
import 'database.dart'; 

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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService(); // Create an instance of FirestoreService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localize'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Add a user to Firestore
                _firestoreService.addUser('userId', 'password123', 'John Doe', 'USA', 'New York', 'john@example.com', ['traveling', 'food']);
              },
              child: const Text('Add User to Firestore'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Fetch users from Firestore
                await _firestoreService.getUsers(); 
              },
              child: const Text('Get Users from Firestore'),
            ),
          ],
        ),
      ),
    );
  }
}