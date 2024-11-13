import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
class PostLike extends StatefulWidget {
    final String? passed_user_uid;
  final String? passed_review_id;
  final List? passed_likeCount ;
  const PostLike({ required this.passed_user_uid, required this.passed_review_id, required this.passed_likeCount});
  @override
  _PostLikeState createState() => _PostLikeState();
}

class _PostLikeState extends State<PostLike> {

  late String reviewID;
  late String userID;
 late List? _likeCount ;
  @override
  void initState() {
    super.initState();
    
    // Initialize variables from widget properties
    reviewID = widget.passed_review_id ?? 'Unknown Review ID';
    userID = widget.passed_user_uid ?? 'Unknown User ID';
    _likeCount = widget.passed_likeCount; 
  }
  Future<void> likePost(
    BuildContext context,
  ) async {
    try {
      debugPrint("++++++++++++++likePost++++++++++");
      debugPrint("review_id" + reviewID);
      debugPrint("user_uid" + userID);

      await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewID)
          .update(
        {
          'Like_count': FieldValue.arrayUnion([userID])
        },
      );
    } on FirebaseException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error liking post'),
        ),
      );
    }
  }

  Future<void> dislikePost(
    BuildContext context,
  ) async {
    try {
      debugPrint("++++++++++++++dislikePost++++++++++");
      debugPrint("review_id" + reviewID);
      debugPrint("user_uid" + userID);
      await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewID)
          .update(
        {
          'Like_count': FieldValue.arrayRemove([userID])
        },
      );
    } on FirebaseException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error liking post'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  return                             Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: (_likeCount != null && _likeCount!.contains(userID))
                                          ? const Icon(
                                              Ionicons.heart,
                                              color: Color.fromARGB(
                                                  255, 213, 56, 16),
                                            )
                                          : const Icon(
                                              Ionicons.heart_outline,
                                              color: Color.fromARGB(
                                                  255, 136, 136, 136),
                                            ),
                                      splashColor:
                                          const Color.fromARGB(0, 176, 80, 80),
                                      highlightColor: const Color.fromARGB(
                                          0, 127, 111, 111),
                                      onPressed: () {
                                        if (_likeCount != null && _likeCount!.contains(userID)) {
                                          dislikePost(context);
                                        } else {
                                          likePost(context);
                                        }
                                      },
                                    ),
  Text(
  _likeCount != null ? _likeCount!.length.toString() : '0',
  style: const TextStyle(
    color: Colors.grey,
  ),
)
                                  ],
                                ),
                               // Icon(Icons.bookmark, color: Colors.grey),
                              ],
                            );
  }
}