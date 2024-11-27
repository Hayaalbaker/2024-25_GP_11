import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {

  Future<bool> isBookmarked(String reviewId) async {
    String? activeUserId = FirebaseAuth.instance.currentUser?.uid;
    if (activeUserId == null) return false;

    final reviewRef = FirebaseFirestore.instance
        .collection('bookmarks')
        .doc(activeUserId)
        .collection('reviews')
        .doc(reviewId);

    final doc = await reviewRef.get();
    return doc.exists;  
  }

  Future<void> toggleBookmark(String reviewId) async {
    String? activeUserId = FirebaseAuth.instance.currentUser?.uid;
    if (activeUserId == null) return;

    final reviewRef = FirebaseFirestore.instance
        .collection('bookmarks')
        .doc(activeUserId)
        .collection('reviews')
        .doc(reviewId);

    final reviewDoc = await FirebaseFirestore.instance
        .collection('Review')
        .doc(reviewId)
        .get();

    if (!reviewDoc.exists) {
      print('Review does not exist');
      return;
    }

    final doc = await reviewRef.get();

    if (doc.exists) {
      await reviewRef.delete();
    } else {
      final bookmarkData = {
        'bookmark_id': reviewId,
        'user_uid': activeUserId,
        'bookmark_date': FieldValue.serverTimestamp(),
        'bookmark_type': 'review',
      };
      await reviewRef.set(bookmarkData);
    }
  }
  
static Future<void> addBookmark(String targetId, String type) async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final bookmarkDoc = FirebaseFirestore.instance.collection('bookmarks').doc();

      final bookmarkData = {
        'bookmark_id': bookmarkDoc.id, 
        'user_uid': user.uid,         
        'target_id': targetId,       
        'bookmark_type': type,       
        'bookmark_date': FieldValue.serverTimestamp(), 
      };

      print("Saving to Firestore: $bookmarkData");

      await bookmarkDoc.set(bookmarkData);

      print('Bookmark added successfully');
    } else {
      print('Error: No user logged in.');
    }
  } catch (e) {
    print('Error adding bookmark: $e');
  }
}

  static Stream<QuerySnapshot> fetchBookmarks(String type) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FirebaseFirestore.instance
          .collection('bookmarks')
          .where('user_uid', isEqualTo: user.uid)
          .where('bookmark_type', isEqualTo: type)
          .orderBy('bookmark_date', descending: true)
          .snapshots();
    } else {
      return const Stream.empty();
    }
  }
}