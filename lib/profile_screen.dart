import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'bookmarks.dart';
import 'report_service.dart';
import 'review_widget.dart';
import 'message_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
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

        _loadUserReviews(widget.userId);
        _loadUserBookmarks(widget.userId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: $e'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
        ),
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
        title: null,
        flexibleSpace: Center(
          child: Text(
            _displayName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (!_isCurrentUser) ...[
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
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'report') {
                  ReportService().navigateToReportScreen(context, widget.userId, 'User');
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Report'),
                ),
              ],
            ),
          ],
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
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _displayName = result['name'] ?? _displayName;
                          _profileImageUrl =
                              result['profileImageUrl'] ?? _profileImageUrl;
                        });
                      }
                    },
                  ),
              ],
            ),
            SizedBox(height: 8),
            Column(
              children: [
                Text(
                  '@$_username',
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsList(),
                  _isCurrentUser
                      ? _buildBookmarksSection()
                      : Center(
                          child: Text(
                            "Bookmarks are private.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return Review_widget(userId: widget.userId);
  }

  Widget _buildBookmarksSection() {
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