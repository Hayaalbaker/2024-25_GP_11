import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // add user
  Future<void> addUser(String userId, String password, String userName, String country, String city, String email, List<String> interests) {
    return _db.collection('users').doc(userId).set({
      'user_id': userId,
      'password': password,
      'user_name': userName,
      'country': country,
      'city': city,
      'email': email,
      'interests': interests,
    });
  }

  // add place
  Future<void> addPlace(String placeId, String placeName, String placeDescription, String location, String category) {
    return _db.collection('places').doc(placeId).set({
      'place_id': placeId,
      'place_name': placeName,
      'place_description': placeDescription,
      'location': location,
      'category': category,
    });
  }

  // add review
  Future<void> addReview(String reviewId, String userId, String placeId, String reviewText, DateTime reviewDate, int like, int dislike) {
    return _db.collection('reviews').doc(reviewId).set({
      'review_id': reviewId,
      'user_id': userId,
      'place_id': placeId,
      'review_text': reviewText,
      'review_date': reviewDate,
      'like': like,
      'dislike': dislike,
    });
  }

  // add bookmark
  Future<void> addBookmark(String bookmarkId, String userId, DateTime bookmarkDate, String bookmarkType) {
    return _db.collection('bookmarks').doc(bookmarkId).set({
      'bookmark_id': bookmarkId,
      'user_id': userId,
      'bookmark_date': bookmarkDate,
      'bookmark_type': bookmarkType,
    });
  }

  // add message
  Future<void> addMessage(String messageId, String senderId, String receiverId, String messageContent, DateTime messageDate, String status) {
    return _db.collection('messages').doc(messageId).set({
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_content': messageContent,
      'message_date': messageDate,
      'status': status,
    });
  }

  // add report
  Future<void> addReport(String reportId, String userId, String adminId, String reportDescription, DateTime reportDate, String status) {
    return _db.collection('reports').doc(reportId).set({
      'report_id': reportId,
      'user_id': userId,
      'admin_id': adminId,
      'report_description': reportDescription,
      'report_date': reportDate,
      'status': status,
    });
  }

  // add admin
  Future<void> addAdmin(String adminId, String adminName, String email, String password) {
    return _db.collection('admins').doc(adminId).set({
      'admin_id': adminId,
      'admin_name': adminName,
      'email': email,
      'password': password,
    });
  }
}