import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'bookmarks.dart';
import 'review_widget.dart';
import 'message_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profileImageUrl = '';
  String _displayName = 'Display Name';
  String _username = 'Username';
  bool _isLocalGuide = false;

  List<DocumentSnapshot> _reviews = [];
  List<DocumentSnapshot> _bookmarkedReviews = [];
  List<DocumentSnapshot> _bookmarkedPlaces = [];

  bool _isCurrentUser = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == _auth.currentUser?.uid;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          var data = userDoc.data() as Map<String, dynamic>;
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _displayName = data['Name'] ?? 'Display Name';
          _username = data['user_name'] ?? 'Username';
          _isLocalGuide = data['local_guide'] == 'yes';
        });

        // Load reviews and bookmarks
        _loadUserReviews(widget.userId);
        _loadUserBookmarks(widget.userId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

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
        actions: [
          if (!_isCurrentUser)
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageScreen(
                      currentUserId: _auth.currentUser!.uid,
                      otherUserId: widget.userId,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
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
                if (_isCurrentUser)
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(),
                        ),
                      );
                    },
                  ),
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
            if (_isCurrentUser)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF800020),
                ),
                child: Text('Edit Profile', style: TextStyle(fontSize: 14)),
              ),
            SizedBox(height: 10),

            // Display TabBar only for current user
            if (_isCurrentUser)
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF800020),
                unselectedLabelColor: Colors.black,
                indicatorColor: const Color(0xFF800020),
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Reviews'),
                  Tab(text: 'Bookmarks'),
                ],
              ),

            // Expanded TabBarView, showing reviews and bookmarks
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsList(),
                  if (_isCurrentUser)
                    _buildBookmarksSection(), // Show bookmarks only for the current user
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Function to display the reviews list
  Widget _buildReviewsList() {
    return Review_widget(userId: widget.userId); // Display reviews for the user
  }

// Function to display bookmarks section
  Widget _buildBookmarksSection() {
    if (!_isCurrentUser) {
      return Container(); // Don't show bookmarks if it's not the current user's profile
    }

    return Column(
      children: [
        SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BookmarkedReviewsScreen()),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
