import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> reportedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchReportedUsers();
  }

  Future<void> fetchReportedUsers() async {
    final reportSnapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('Report_Target_Type', isEqualTo: 'User')
        .get();

    final userIds = reportSnapshot.docs
        .map((doc) => doc['User_ID'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    List<Map<String, dynamic>> users = [];

    for (String userId in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['id'] = userDoc.id;
        users.add(userData);
      }
    }

    setState(() {
      reportedUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader("Reported Users"),
        Expanded(
          child: reportedUsers.isEmpty
              ? const Center(child: Text('No reported users yet.'))
              : ListView.builder(
                  itemCount: reportedUsers.length,
                  itemBuilder: (context, index) {
                    final user = reportedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profileImageUrl'] != null
                            ? NetworkImage(user['profileImageUrl'])
                            : const AssetImage('images/default_profile.png') as ImageProvider,
                      ),
                      title: Text(user['Name'] ?? 'Unknown User'),
                      subtitle: Text('@${user['user_name'] ?? 'username'}'),
                      trailing: const Icon(Icons.warning, color: Colors.red),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}