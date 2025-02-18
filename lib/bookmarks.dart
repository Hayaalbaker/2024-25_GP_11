import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'bookmark_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'places_widget.dart';
import 'review_widget.dart';

class BookmarksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookmarkedReviewsScreen()),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                color: Color(0xFF800020),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Reviews',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookmarkedPlacesScreen()),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                color: Color(0xFF800020),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Places',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarkedReviewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(child: Text('Please log in to view your bookmarked reviews.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookmarks')
            .doc(userId)
            .collection('reviews')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookmarked reviews found.'));
          }

          final bookmarkedReviewIds = snapshot.data!.docs
              .map((doc) => doc['bookmark_id'] as String)
              .toList();

          return Review_widget(
            reviewIds: bookmarkedReviewIds,
          );
        },
      ),
    );
  }
}

class BookmarkedPlacesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Center(child: Text('Please log in to view your bookmarked places.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Places'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookmarks')
            .doc(userId)
            .collection('places') 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No bookmarked places found.'));
          }

          final bookmarkedPlaceIds = snapshot.data!.docs
              .where((doc) =>
                  doc.data() != null &&
                  (doc.data() as Map<String, dynamic>).containsKey('bookmark_id'))
              .map((doc) => (doc.data() as Map<String, dynamic>)['bookmark_id'] as String)
              .toList();


          return PlacesWidget(
            placeIds: bookmarkedPlaceIds,  
          );
        },
      ),
    );
  }
}