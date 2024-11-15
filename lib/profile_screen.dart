import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'message_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profileImageUrl = '';
  String _displayName = 'Display Name';
  String _username = 'Username';
  bool _isLocalGuide = false;
  List<String> _reviews = [];
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == _auth.currentUser?.uid;
    _loadUserProfile();
  }

  void _loadUserProfile() async {
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
            TextButton(
              onPressed: () {
                // التالي سيضاف في المرحلة المقبلة
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF800020),
                backgroundColor: Color.fromARGB(255, 230, 230, 230),
                padding: EdgeInsets.symmetric(horizontal: 66, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 1),
            Expanded(
              child: _reviews.isEmpty
                  ? Center(child: Text('No reviews yet'))
                  : ListView.builder(
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_reviews[index],
                              style: TextStyle(fontSize: 14)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
