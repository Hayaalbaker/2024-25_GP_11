import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add user details to Firestore (excluding password)
  Future<void> addUserDetails(String userName, String country, String city,
      List<String> interests) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'user_name': userName,
          'country': country,
          'city': city,
          'email': user.email,
          'interests': interests,
          'created_at': FieldValue.serverTimestamp(),
        });
        print('User details added successfully');
      }
    } catch (e) {
      print('Error adding user details: $e');
    }
  }

  // Fetch users from Firestore
  Future<void> getUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').get();
      for (var doc in snapshot.docs) {
        print('User: ${doc['user_name']}'); // Log users' names
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // Add place
  Future<void> addPlace(String placeId, String placeName,
      String placeDescription, String location, String category) async {
    try {
      await _db.collection('places').doc(placeId).set({
        'place_name': placeName,
        'place_description': placeDescription,
        'location': location,
        'category': category,
        'created_at': FieldValue.serverTimestamp(),
      });
      print('Place added successfully');
    } catch (e) {
      print('Error adding place: $e');
    }
  }

  // Add review
  Future<void> addReview(String reviewId, String placeId, String reviewText,
      DateTime reviewDate, int like, int dislike) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('reviews').doc(reviewId).set({
          'user_id': user.uid,
          'place_id': placeId,
          'review_text': reviewText,
          'review_date': reviewDate,
          'like': like,
          'dislike': dislike,
          'created_at': FieldValue.serverTimestamp(),
        });
        print('Review added successfully');
      }
    } catch (e) {
      print('Error adding review: $e');
    }
  }

  // Additional methods...
}
