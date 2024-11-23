import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  static Future<void> addBookmark(String targetId, String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('bookmarks').add({
          'user_uid': user.uid,
          'target_id': targetId,
          'bookmark_type': type,
          'bookmark_date': FieldValue.serverTimestamp(),
        });

        print('Bookmark added successfully');
      } else {
        print('User is not logged in');
      }
    } catch (e) {
      print('Failed to add bookmark: $e');
    }
  }
}
