import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';
import 'profile_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountConfirmationPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Anonymize user data
  Future<void> anonymizeUserData(String uid) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // user's reviews to anonymize
    QuerySnapshot reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: uid)
        .get();
    for (QueryDocumentSnapshot doc in reviewsSnapshot.docs) {
      await doc.reference.update({
        'userName': 'Deleted User',
        'deleted': true, 
      });
    }

    // Update user's messages to anonymize
    QuerySnapshot messagesSnapshot = await _firestore
        .collection('messages')
        .where('userId', isEqualTo: uid)
        .get();
    for (QueryDocumentSnapshot doc in messagesSnapshot.docs) {
      await doc.reference.update({
        'senderName': 'Deleted User',
        'deleted': true, 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Confirm Account Deletion"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Are you sure you want to delete your account?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              "Deleting your account will anonymize your data, and this action cannot be undone.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.black, 
              ),
              onPressed: () async {
                User? user = _auth.currentUser;

                if (user != null) {
                  // Step 1: Anonymize user data
                  await anonymizeUserData(user.uid);

                  // Step 2: Delete the user's Firebase Authentication account
                  await user.delete();

                  // Step 3: Navigate to the sign-in screen after account deletion
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: Text("Yes, delete my account"),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}