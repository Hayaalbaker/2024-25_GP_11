import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profileImageUrl = '';
  String _displayName = 'displayName'; // Default values to avoid null issues
  String _username = 'Username';
  bool _isLocalGuide = false;
  List<String> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            var data = userDoc.data() as Map<String, dynamic>;

            _displayName = data['Name'] ?? 'Display Name';
            _username = data['user_name'] ?? 'Username';
            _isLocalGuide = data['local_guide'] == 'yes';
          });
        }
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
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
                          ? NetworkImage(_profileImageUrl)
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
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
            Text(
              _displayName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isLocalGuide)
              Text(
                'Local Guide',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            Text(
              '@$_username',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 10),
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
                backgroundColor: const Color.fromARGB(255, 222, 139, 139), // لون نص الزر
              ),
              child: Text('Edit Profile', style: TextStyle(fontSize: 14)),
            ),
            SizedBox(height: 10),
            Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
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
