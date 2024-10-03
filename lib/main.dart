import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

void main() async {
  // Ensure the Flutter environment is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized(); 

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the Flutter app
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

// ignore: must_be_immutable
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Localize'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                addUser(); // Trigger Firestore add user
              },
              child: Text('Add User to Firestore'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                getUsers(); // Trigger Firestore fetch users
              },
              child: Text('Get Users from Firestore'),
            ),
          ],
        ),
      ),
    );
  }

  // Firestore instance
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Add user to Firestore
  Future<void> addUser() async {
    await firestore.collection('users').add({
      'name': 'John Doe',
      'email': 'johndoe@example.com',
    });
    print('User added to Firestore');
  }

  // Fetch users from Firestore
  Future<void> getUsers() async {
    QuerySnapshot snapshot = await firestore.collection('users').get();
    for (var doc in snapshot.docs) {
      print('User: ${doc['name']}'); // Log users' names
    }
  }
}