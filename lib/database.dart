import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addUserDetails(String userName, String country, String city,
      List<String> interests, bool isLocalGuide, {String? profileImageUrl}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'user_name': userName,
          'country': country,
          'city': city,
          'email': user.email,
          'interests': interests,
          'local_guide': isLocalGuide ? 'yes' : 'no', 
          'created_at': FieldValue.serverTimestamp(),
          'Name': user.displayName,
          'profileImageUrl': profileImageUrl ?? '', 
        });
        print('User details added successfully');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding user details: $e');
    }
  }
}
