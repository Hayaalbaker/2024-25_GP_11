import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bookmark_service.dart';
import 'create_post_page.dart';
import 'otherUser_profile.dart';
import 'post_like.dart';
import 'database.dart';
import 'profile_screen.dart';
import 'report_service.dart';
import 'view_Place.dart';

class Review_widget extends StatefulWidget {
  final String? place_Id;
  final String? userId;
  final List<String>? reviewIds;

  Review_widget({this.place_Id, this.userId, this.reviewIds});

  @override
  _Review_widgetState createState() => _Review_widgetState();
}

class _Review_widgetState extends State<Review_widget> {
  String? active_userid;
  final ReportService _reportService = ReportService();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, bool> bookmarkedReviews = {};

@override
void initState() {
  super.initState();
  _loadUserData();
  _loadBookmarks();
  FirebaseFirestore.instance.collection('Review').get().then((snapshot) {
  if (snapshot.docs.isEmpty) {
    print("No reviews found in Firestore.");
  } else {
    print("Reviews found: ${snapshot.docs.length}");
  }
});
}

Future<void> _loadBookmarks() async {
  if (active_userid == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('bookmarks')
      .doc(active_userid)
      .collection('reviews')
      .get();

  Map<String, bool> tempBookmarks = {};
  for (var doc in snapshot.docs) {
    tempBookmarks[doc.id] = true;
  }

  if (!mounted) return; 

  setState(() {
    bookmarkedReviews = tempBookmarks;
  });
}

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          active_userid = user.uid;
        });
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

Future<void> toggleBookmark(String reviewId) async {
  if (active_userid == null) return;

  final reviewRef = FirebaseFirestore.instance
      .collection('bookmarks')
      .doc(active_userid)
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

  if (!mounted) return;  

  if (doc.exists) {
    await reviewRef.delete();
    setState(() {
      bookmarkedReviews[reviewId] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review unbookmarked'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
    );
  } else {
    final bookmarkData = {
      'bookmark_id': reviewId,
      'user_uid': active_userid,
      'bookmark_date': FieldValue.serverTimestamp(),
      'bookmark_type': 'review',
    };

    await reviewRef.set(bookmarkData);
    setState(() {
      bookmarkedReviews[reviewId] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review bookmarked'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
    );
  }
}

  Future<void> deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Review')
          .doc(reviewId)
          .delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Review deleted"),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to delete review"),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),));
    }
  }

  Future<void> _showDeleteConfirmationDialog(String reviewId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Review'),
          content: Text('Are you sure you want to delete this review?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteReview(reviewId);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.userId != null
    ? FirebaseFirestore.instance
        .collection('Review')
        .where('user_uid', isEqualTo: widget.userId)
        .orderBy('Post_Date', descending: true)
        .snapshots()
    : FirebaseFirestore.instance
        .collection('Review')
        .orderBy('Post_Date', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No reviews available.'));
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          if (widget.reviewIds != null) {
            return widget.reviewIds!.contains(doc.id);
            }
            return widget.place_Id == null || doc['placeId'] == widget.place_Id;
          }).toList();

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredDocs.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey[300],
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];
            String review_id = doc.id;
            String reviewText = doc['Review_Text'];
            String placeId = doc['placeId'];
            String userUid = doc['user_uid'];
            int rating = doc['Rating'];
            List? likeCount = doc['Like_count'];

            return FutureBuilder(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userUid)
                    .get(),
                FirebaseFirestore.instance
                    .collection('places')
                    .doc(placeId)
                    .get(),
              ]),
              builder: (context,
                  AsyncSnapshot<List<DocumentSnapshot>> asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (asyncSnapshot.hasData) {
                  final userDoc = asyncSnapshot.data![0];
                  final Name =
                      (userDoc.data() as Map<String, dynamic>?)?['Name'] ??
                          'Unknown User';
                  final profileImageUrl = (userDoc.data()
                          as Map<String, dynamic>?)?['profileImageUrl'] ??
                      'images/default_profile.png';
final placeDoc = asyncSnapshot.data![1];

final placeName = placeDoc.exists && placeDoc.data() != null
    ? (placeDoc.data() as Map<String, dynamic>)['place_name'] ?? 'Unknown Place'
    : 'Unknown Place';
                      final userData = userDoc.data() as Map<String, dynamic>?;
                  final _isLocalGuide = userData != null &&
                      userData.containsKey('local_guide') &&
                      userData['local_guide'] == 'yes';

                  bool isBookmarked = bookmarkedReviews[review_id] ?? false;

                  return Card(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 4),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(userId: userDoc.id)
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  backgroundImage:
                                        (Uri.tryParse(profileImageUrl)?.isAbsolute == true
              ? NetworkImage(profileImageUrl) as ImageProvider<Object>
              : AssetImage(profileImageUrl) as ImageProvider<Object>),
                                  radius: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (userUid == active_userid) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileScreen(
                                                        userId: FirebaseAuth
                                                            .instance
                                                            .currentUser!
                                                            .uid),
                                              ),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileScreen(userId: userDoc.id)
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(children: [ 
                                        Text(
                                          '$Name ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        if (_isLocalGuide) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                            ),
                                            ],
                                        ],
                                      )
                                    ),
                                  ],
                                  ),
                                   Row(
                                     children: [ 
                                      Text(
                                        'reviewed',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewPlace(place_Id: placeId),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          ' $placeName',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: const Color(0xFF800020),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        userData != null && userData.containsKey('city') ? 
                                        'Based in ${userData['city']}' : 
                                        'Based in ?',
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 4),
                                ],
                              ),
                              Spacer(),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.black),
                            onSelected: (value) {
                              if (value == 'delete') {
                                if (userUid == active_userid) {
                                  _showDeleteConfirmationDialog(review_id);
                                }
                              } else if (value == 'report') {
                                _reportService.navigateToReportScreen(context, review_id, 'Review');
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                if (userUid == active_userid)
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text(
                                      'Delete Review',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                if (userUid != active_userid) 
                                  PopupMenuItem<String>(
                                    value: 'report',
                                    child: Text('Report'),
                                  ),                                
                              ];
                            },
                          ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                          SizedBox(height: 12),
                          Text(
                            reviewText,
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[800]),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              PostLike(
                                  passed_user_uid: active_userid,
                                  passed_review_id: review_id,
                                  passed_likeCount: likeCount),
                              Spacer(),
                              SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color:
                                      isBookmarked ? Color(0xFF800020) : Colors.grey,
                                ),
                                onPressed: () async {
                                  await toggleBookmark(review_id); 
                                 },
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(child: Text("Error loading review data"));
                }
              },
            );
          },
        );
      },
    );
  }
}