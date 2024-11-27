import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountConfirmationPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> deleteUserData(String uid) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: uid)
        .get();
    for (QueryDocumentSnapshot doc in reviewsSnapshot.docs) {
      await doc.reference.delete();
    }

    QuerySnapshot messagesSnapshot = await _firestore
        .collection('messages')
        .where('userId', isEqualTo: uid)
        .get();
    for (QueryDocumentSnapshot doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;

      try {
        await deleteUserData(uid);

        await user.delete();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting account: $e"),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
        );
      }
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text(
            "Are you absolutely sure you want to delete your account? "
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
              },
              child: Text("Cancel"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); 
                await _confirmAccountDeletion(context); 
              },
              child: Text("Yes, Delete"),
            ),
          ],
        );
      },
    );
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
              "Deleting your account will remove all your data, and this action cannot be undone.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                _showConfirmationDialog(context);
              },
              child: Text("Delete My Account"),
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