import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_page.dart';
import 'otherUser_profile.dart';
import 'post_like.dart';
import 'database.dart';
import 'profile_screen.dart';  
import 'view_Place.dart';  

class Review_widget extends StatefulWidget {
  final String? place_Id;
  final String? userId;  // Added userId parameter

  Review_widget({this.place_Id, this.userId}); // Modify constructor

  @override
  _Review_widgetState createState() => _Review_widgetState();
}

class _Review_widgetState extends State<Review_widget> {
  String? active_userid;

  final FirestoreService _firestoreService = FirestoreService();

  Map<String, bool> bookmarkedReviews = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

    final userRef = FirebaseFirestore.instance.collection('users').doc(active_userid);
    final userDoc = await userRef.get();
    final bookmarks = List<String>.from(userDoc.data()?['bookmarks'] ?? []);

    setState(() {
      if (bookmarks.contains(reviewId)) {
        bookmarks.remove(reviewId); 
        bookmarkedReviews[reviewId] = false; 
      } else {
        bookmarks.add(reviewId); 
        bookmarkedReviews[reviewId] = true; 
      }
    });

    await userRef.update({'bookmarks': bookmarks});
  }

@override
Widget build(BuildContext context) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('Review')
        // Apply filter if userId is provided
        .where('user_uid', isEqualTo: widget.userId)
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
        // If placeId is provided, filter by placeId as well
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
              FirebaseFirestore.instance.collection('users').doc(userUid).get(),
              FirebaseFirestore.instance.collection('places').doc(placeId).get(),
            ]),
            builder: (context, AsyncSnapshot<List<DocumentSnapshot>> asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (asyncSnapshot.hasData) {
                final userDoc = asyncSnapshot.data![0];
                final placeDoc = asyncSnapshot.data![1];
                final Name = (userDoc.data() as Map<String, dynamic>?)?['Name'] ?? 'Unknown User';
                final profileImageUrl = (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] ?? 'images/default_profile.png';
                final placeName = placeDoc['place_name'];
                final userData = userDoc.data() as Map<String, dynamic>?;
                final _isLocalGuide = userData != null && userData.containsKey('local_guide') && userData['local_guide'] == 'yes';

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
                        // User and Place Information
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Navigate to the user's profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtherUserProfileScreen(userId: userUid), // Use actual userUid
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(profileImageUrl),
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
                                        // Navigate to the profile of the user
                                        if (userUid == active_userid) {
                                          // If it's the logged-in user, go to ProfileScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfileScreen(), // Your own profile
                                            ),
                                          );
                                        } else {
                                          // If it's another user, go to OtherUserProfileScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OtherUserProfileScreen(userId: userUid), // Pass the other user's UID
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        '$Name ', // User's name
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, // Bold for name only
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'reviewed', // The "reviewed" text, not bold
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal, // Normal weight for "reviewed"
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to the place details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewPlace(place_Id: placeId),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        ' $placeName', // The place name
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, // You can keep this bold or adjust to your preference
                                          fontSize: 16,
                                          color: const Color(0xFF800020), // Color to distinguish the place name
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                _isLocalGuide
                                    ? Row(
                                        children: [
                                          Text(
                                            'Local Guide',
                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Text(
                                            'Normal User',
                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.grey,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                SizedBox(height: 4),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Rating Stars
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

                        // Review Text
                        Text(
                          reviewText,
                          style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                        ),
                        SizedBox(height: 5),

                        // Like and Bookmark Icons (Ensure only one bookmark icon)
                        Row(
                          children: [
                            PostLike(passed_user_uid: active_userid, passed_review_id: review_id, passed_likeCount: likeCount),
                            Spacer(),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: isBookmarked ? Colors.blue : Colors.grey, // Adjust color
                              ),
                              onPressed: () {
                                toggleBookmark(review_id);
                                setState(() {}); // Refresh the widget to show bookmark change
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