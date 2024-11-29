import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ionicons/ionicons.dart';
import 'profile_screen.dart';

class PostLike extends StatefulWidget {
  final String? passed_user_uid;
  final String? passed_review_id;
  final List? passed_likeCount;

  const PostLike({
    required this.passed_user_uid,
    required this.passed_review_id,
    required this.passed_likeCount,
  });

  @override
  _PostLikeState createState() => _PostLikeState();
}

class _PostLikeState extends State<PostLike> {
  late String reviewID;
  late String userID;
  late List? _likeCount;

  @override
  void initState() {
    super.initState();
    reviewID = widget.passed_review_id ?? 'Unknown Review ID';
    userID = widget.passed_user_uid ?? 'Unknown User ID';
    _likeCount = widget.passed_likeCount;
  }

  Future<void> likePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewID)
          .update({
        'Like_count': FieldValue.arrayUnion([userID])
      });

      await _sendNotification();
    } on FirebaseException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error liking post'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
      );
    }
  }

  Future<void> dislikePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewID)
          .update({
        'Like_count': FieldValue.arrayRemove([userID])
      });

      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('reviewId', isEqualTo: reviewID)
          .where('senderUid', isEqualTo: userID)
          .where('type', isEqualTo: 'like')
          .get();

      for (var doc in notificationSnapshot.docs) {
        await FirebaseFirestore.instance
            .collection('Notifications')
            .doc(doc.id)
            .delete();
      }
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error disliking post: ${e.message}'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
      );
    }
  }

  Future<void> _sendNotification() async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewID)
          .get();

      if (reviewDoc.exists) {
        String reviewOwnerId = reviewDoc['user_uid'];
        String reviewText = reviewDoc['Review_Text'] ?? '';

        if (reviewOwnerId != userID) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          String senderName = userDoc.data()?['user_name'] ?? 'Unknown';

          await FirebaseFirestore.instance.collection('Notifications').add({
            'receiverUid': reviewOwnerId,
            'senderUid': userID,
            'senderName': senderName,
            'reviewId': reviewID,
            'reviewText': reviewText,
            'type': 'like',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  void _showLikes(BuildContext context) async {
    if (_likeCount == null || _likeCount!.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<DocumentSnapshot>>(
          future: _fetchLikers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('No likes yet'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final userDoc = snapshot.data![index];
                final userName = userDoc['user_name'] ?? 'Unknown';
                final userId = userDoc.id;

                return ListTile(
                  title: Text(userName),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: userId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchLikers() async {
    List<DocumentSnapshot> userDocs = [];
    for (String likerId in _likeCount!) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(likerId)
          .get();
      if (userDoc.exists) {
        userDocs.add(userDoc);
      }
    }
    return userDocs;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: (_likeCount != null && _likeCount!.contains(userID))
              ? const Icon(Ionicons.heart, color: Colors.red)
              : const Icon(Ionicons.heart_outline, color: Colors.grey),
          onPressed: () {
            if (_likeCount != null && _likeCount!.contains(userID)) {
              dislikePost(context);
            } else {
              likePost(context);
            }
          },
        ),
        GestureDetector(
          onTap: () => _showLikes(context),
          child: Text(
            _likeCount != null ? _likeCount!.length.toString() : '0',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}  
