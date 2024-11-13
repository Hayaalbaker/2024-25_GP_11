import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bookmarks.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  OtherUserProfileScreen({required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profileImageUrl = '';
  String _displayName = 'displayName';
  String _username = 'Username';
  bool _isLocalGuide = false;
  
  List<DocumentSnapshot> _reviews = [];
  List<DocumentSnapshot> _bookmarkedReviews = [];
  List<DocumentSnapshot> _bookmarkedPlaces = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(widget.userId); // Load profile data for the passed userId
    _tabController = TabController(length: 2, vsync: this);
  }

  void _loadUserProfile(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          var data = userDoc.data() as Map<String, dynamic>;
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _displayName = data['Name'] ?? 'Display Name';
          _username = data['user_name'] ?? 'Username';
          _isLocalGuide = data['local_guide'] == 'yes';
        });

        // Load the user's reviews (these are public)
        _loadUserReviews(userId);

        // Load bookmarks only if this is the logged-in user
        User? currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          _loadUserBookmarks(userId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  // Load reviews for the other user
  void _loadUserReviews(String userId) async {
    try {
      var reviewSnapshot = await _firestore
          .collection('Review')
          .where('user_uid', isEqualTo: userId)
          .get();
      setState(() {
        _reviews = reviewSnapshot.docs;
      });
    } catch (e) {
      print("Error loading reviews: $e");
    }
  }

  // Load bookmarks for the logged-in user only
  void _loadUserBookmarks(String userId) async {
    try {
      var bookmarkReviewsSnapshot = await _firestore
          .collection('bookmarks')
          .where('user_uid', isEqualTo: userId)
          .where('type', isEqualTo: 'review')
          .get();
      var bookmarkPlacesSnapshot = await _firestore
          .collection('bookmarks')
          .where('user_uid', isEqualTo: userId)
          .where('type', isEqualTo: 'place')
          .get();

      setState(() {
        _bookmarkedReviews = bookmarkReviewsSnapshot.docs;
        _bookmarkedPlaces = bookmarkPlacesSnapshot.docs;
      });
    } catch (e) {
      print("Error loading bookmarks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Profile Picture and User Info
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: _isLocalGuide
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                    image: DecorationImage(
                      image: _profileImageUrl.isNotEmpty
                          ? NetworkImage(_profileImageUrl) as ImageProvider
                          : AssetImage('images/default_profile.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Hide edit button for other users' profile
              ],
            ),
            SizedBox(height: 8),
            Column(
              children: [
                Text(
                  _displayName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLocalGuide)
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                  ),
                Text(
                  '@$_username',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            // TabBar for Reviews and Bookmarks
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              indicatorColor: const Color(0xFF800020),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Reviews'),
                Tab(text: 'Bookmarks'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsList(),
                  _buildBookmarksSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display the user's reviews
  Widget _buildReviewsList() {
    return _reviews.isEmpty
        ? Center(child: Text('No reviews yet'))
        : ListView.builder(
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              var review = _reviews[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(review['Review_Text'], style: TextStyle(fontSize: 14)),
              );
            },
          );
  }

  // Widget to display the bookmarks section
  Widget _buildBookmarksSection() {
    // Hide bookmarks section for other users
    if (_bookmarkedReviews.isEmpty && _bookmarkedPlaces.isEmpty) {
      return Center(child: Text('No bookmarks yet'));
    }
    return Column(
      children: [
        SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookmarkedReviewsScreen()),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              MaterialPageRoute(builder: (context) => BookmarkedPlacesScreen()),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}