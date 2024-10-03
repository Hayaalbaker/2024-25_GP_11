import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add user
  Future<void> addUser(String userId, String password, String userName, String country, String city, String email, List<String> interests) async {
    try {
      await _db.collection('users').doc(userId).set({
        'user_id': userId,
        'password': password,
        'user_name': userName,
        'country': country,
        'city': city,
        'email': email,
        'interests': interests,
      });
      print('User added successfully');
    } catch (e) {
      print('Error adding user: $e');
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
  Future<void> addPlace(String placeId, String placeName, String placeDescription, String location, String category) async {
    try {
      await _db.collection('places').doc(placeId).set({
        'place_id': placeId,
        'place_name': placeName,
        'place_description': placeDescription,
        'location': location,
        'category': category,
      });
      print('Place added successfully');
    } catch (e) {
      print('Error adding place: $e');
    }
  }

  // Add review
  Future<void> addReview(String reviewId, String userId, String placeId, String reviewText, DateTime reviewDate, int like, int dislike) async {
    try {
      await _db.collection('reviews').doc(reviewId).set({
        'review_id': reviewId,
        'user_id': userId,
        'place_id': placeId,
        'review_text': reviewText,
        'review_date': reviewDate,
        'like': like,
        'dislike': dislike,
      });
      print('Review added successfully');
    } catch (e) {
      print('Error adding review: $e');
    }
  }

  // Additional methods...
}