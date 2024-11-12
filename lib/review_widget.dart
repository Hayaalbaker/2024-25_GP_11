import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_page.dart';
import 'post_like.dart';
import 'database.dart';

class Review_widget extends StatefulWidget {
  final String? place_Id;

  Review_widget({this.place_Id});

  @override
  _Review_widgetState createState() => _Review_widgetState();
}

class _Review_widgetState extends State<Review_widget> {
  String? active_userid;

  final FirestoreService _firestoreService = FirestoreService(); // Create an instance of FirestoreService

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
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

        // Filter documents based on placeId if it's not null
        final filteredDocs = snapshot.data!.docs.where((doc) {
          return widget.place_Id == null || doc['placeId'] == widget.place_Id;
        }).toList();

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredDocs.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey[300], // Light grey color for separation line
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
                  final userData = userDoc.data() as Map<String, dynamic>?; // Cast to Map if data() isn't null
                  final _isLocalGuide = userData != null && userData.containsKey('local_guide') ? userData['local_guide'] == 'yes' : false;

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
                              CircleAvatar(
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : AssetImage('images/default_profile.png') as ImageProvider,
                                radius: 24,
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
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
                                  Text(
                                    placeName,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
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

                          // Like and Bookmark Icons
                          PostLike(passed_user_uid: active_userid, passed_review_id: review_id, passed_likeCount: likeCount),
                          SizedBox(height: 5),
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
