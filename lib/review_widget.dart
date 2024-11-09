import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReviewsList(),
    );
  }
}

class ReviewsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Review')
          .orderBy('Post_Date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            itemCount: documents.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[300], // Light grey color for separation line
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              var doc = documents[index];
              String reviewText = doc['Review_Text'];
              String placeId = doc['placeId'];
              String userUid = doc['user_uid'];
              int rating = doc['Rating'];
              int likeCount = doc['Like_count'];

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
                    final userName = (userDoc.data() as Map<String, dynamic>?)?['user_name'] ?? 'Unknown User';
                    final profileImageUrl = (userDoc.data() as Map<String, dynamic>?)?['profileImageUrl'] ?? 'images/default_profile.png';
                    final placeName = placeDoc['place_name'];

                    return Card(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
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
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
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
                            SizedBox(height: 16),

                            // Like and Bookmark Icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.favorite, color: likeCount > 0 ? Colors.redAccent : Colors.grey),
                                    SizedBox(width: 4),
                                    Text('$likeCount', style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                                Icon(Icons.bookmark, color: Colors.grey),
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
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(child: Text("No reviews available."));
        }
      },
    );
  }
}