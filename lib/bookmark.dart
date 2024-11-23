import 'package:flutter/material.dart';

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
                  MaterialPageRoute(
                      builder: (context) => BookmarkedReviewsScreen()),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                color: Color(0xFF800020),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Bookmarked Reviews',
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
                  MaterialPageRoute(
                      builder: (context) => BookmarkedPlacesScreen()),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                color: Color(0xFF800020),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Bookmarked Places',
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
    // Display bookmarked reviews here
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Reviews'),
      ),
      body: Center(
        child: Text('Display bookmarked reviews here'),
      ),
    );
  }
}

class BookmarkedPlacesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Display bookmarked places here
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarked Places'),
      ),
      body: Center(
        child: Text('Display bookmarked places here'),
      ),
    );
  }
}
