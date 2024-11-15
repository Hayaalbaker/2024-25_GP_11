import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

class UserSearchPage extends StatefulWidget {
  @override
  _UserSearchPageState createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];

  void _searchUsers() async {
    String searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user_name', isEqualTo: searchQuery)
          .get();

      setState(() {
        _searchResults = snapshot.docs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var userDoc = _searchResults[index];
                  String profileImageUrl = userDoc['profileImageUrl'] ?? '';

                  return ListTile(
                    leading: profileImageUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(profileImageUrl),
                          )
                        : CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                    title: Text(userDoc['Name']),
                    subtitle: Text(userDoc['user_name']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(userId: userDoc.id),
                        ),
                      );
                    },
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
