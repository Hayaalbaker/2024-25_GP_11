import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'review_widget.dart';

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(widget.userId); 
    _tabController = TabController(length: 1, vsync: this); 
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

        _loadUserReviews(userId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
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
            ElevatedButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => Message page(),
                //   ),
                // );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF800020),
              ),
              child: Text('Message', style: TextStyle(fontSize: 14)),
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
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewsList(),
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
}