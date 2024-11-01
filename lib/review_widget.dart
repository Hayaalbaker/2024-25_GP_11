import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_Place.dart';
import 'profile_screen.dart';

class Review_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReviewsList(), // Display the PlacesList widget
    );
  }
}


class ReviewsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Review')
          .orderBy('Post_Date', descending: true) // Order by timestamp
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView(
            children: documents.map((doc) {
              // Retrieve relevant fields from the Review document
              String reviewText = doc['Review_Text'];
              String placeId = doc['placeId'];
              String userUid = doc['user_uid'];
              int rating = doc['Rating'];
              int likeCount = doc['Like_count'];
              
              return FutureBuilder(
                future: Future.wait([
                  // Fetch user data
                  FirebaseFirestore.instance.collection('users').doc(userUid).get(),
                  // Fetch place data
                  FirebaseFirestore.instance.collection('places').doc(placeId).get(),
                ]),
                builder: (context, AsyncSnapshot<List<DocumentSnapshot>> asyncSnapshot) {
                  if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (asyncSnapshot.hasData) {
                    final userDoc = asyncSnapshot.data![0];
                    final placeDoc = asyncSnapshot.data![1];
                    var data  = userDoc.data();
                    final userName = (userDoc.data() as Map<String, dynamic>?)?['user_name'] ?? 'Unknown User';
                  final profileImageUrl = (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] ?? 'images/default_profile.png';
                    final placeName = placeDoc['place_name'];
                    
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User and Place Information
                            Row(
                              children: [
                               /* CircleAvatar(
                                  backgroundImage: profileImageUrl != null 
                                      ? NetworkImage(profileImageUrl)
                                      : AssetImage('images/default_profile.png') as ImageProvider,
                                ),*/
                                SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(placeName, style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),

                            // Rating Stars
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            SizedBox(height: 8),

                            // Review Text
                            Text(
                              reviewText,
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),

                            // Like and Bookmark Icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.favorite),
                                  color: likeCount > 0 ? Colors.red : Colors.grey,
                                  onPressed: () {
                                    // Add like functionality here
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.bookmark),
                                  color: Colors.grey,
                                  onPressed: () {
                                    // Add bookmark functionality here
                                  },
                                ),
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
            }).toList(),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(child: Text("No reviews available."));
        }
      },
    );
  }
}

