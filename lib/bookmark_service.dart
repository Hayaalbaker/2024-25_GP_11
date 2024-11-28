import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  // This method will stream the bookmark status for a place or review
  Stream<bool> bookmarkStream(String targetId, String type) {
    String? activeUserId = FirebaseAuth.instance.currentUser?.uid;
    if (activeUserId == null) return Stream.value(false);

    final targetRef = FirebaseFirestore.instance
        .collection('bookmarks')
        .doc(activeUserId)
        .collection(type) // 'places' or 'reviews'
        .doc(targetId);

    return targetRef.snapshots().map((docSnapshot) {
      return docSnapshot.exists; // Return true if the document exists (bookmarked), false otherwise
    });
  }

  Future<void> toggleBookmark(String targetId, String type) async {
    String? activeUserId = FirebaseAuth.instance.currentUser?.uid;
    if (activeUserId == null) return;

    final targetRef = FirebaseFirestore.instance
        .collection('bookmarks')
        .doc(activeUserId)
        .collection(type) // 'places' or 'reviews'
        .doc(targetId);

    final doc = await targetRef.get();

    if (doc.exists) {
      // Remove bookmark if it exists
      await targetRef.delete();
      print('Bookmark removed for $type: $targetId');
    } else {
      // Create bookmark if it doesn't exist
      final bookmarkData = {
        'bookmark_id': targetId,          // Target ID for the bookmark (place or review)
        'user_uid': activeUserId,         // User ID who made the bookmark
        'bookmark_date': FieldValue.serverTimestamp(),  // Timestamp for when it was bookmarked
        'bookmark_type': type,            // 'places' or 'reviews'
      };

      // Add the new bookmark data
      await targetRef.set(bookmarkData);
      print('Bookmark added for $type: $targetId');
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