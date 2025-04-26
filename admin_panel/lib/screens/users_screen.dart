import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:admin_panel/utils/warning_service.dart';

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
    final reportsSnapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('Report_Target_Type', isEqualTo: 'User')
        .orderBy('Report_Date', descending: true)
        .get();

    Map<String, dynamic> groupedReports = {};

    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();
      final userId = data['User_ID'];
      if (userId == null) continue;

      if (!groupedReports.containsKey(userId)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        groupedReports[userId] = {
          'userId': userId,
          'userName': userDoc['user_name'],
          'name': userDoc['Name'],
          'email': userDoc['email'],
          'profileImageUrl': userDoc['profileImageUrl'],
          'status': data['Status'],
          'reportDescription': data['Report_Description'],
          'reportedById': data['ReportedBy'],
          'reportId': doc.id,
        };
      }
    }

    setState(() {
      reportedUsers = groupedReports.values.toList().cast<Map<String, dynamic>>();
    });
  }

  Future<void> rejectReport(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'Status': 'Rejected',
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report rejected.")));
    fetchReportedUsers(); // Refresh
  }

  Future<void> deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted.")));
    fetchReportedUsers(); // Refresh
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['profileImageUrl'] != null
                                ? NetworkImage(user['profileImageUrl'])
                                : const AssetImage('images/default_profile.png') as ImageProvider,
                          ),
                          title: Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${user['userName'] ?? 'username'}'),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Status: ${user['status'] ?? 'Unknown'}', style: const TextStyle(color: Colors.orange)),
                                    if (user['reportDescription'] != null && user['reportDescription'].toString().isNotEmpty)
                                      Text('Reason: ${user['reportDescription']}'),
                                    if (user['reportedById'] != null)
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('users').doc(user['reportedById']).get(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                                          final reporterEmail = snapshot.data!['email'] ?? 'unknown@example.com';
                                          return Text('Reported by: $reporterEmail');
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'Warning') {
                                await WarningService.sendWarning(context, user['userId'], user['email']);
                              } else if (value == 'Reject') {
                                await rejectReport(user['reportId']);
                              } else if (value == 'Delete') {
                                await deleteUser(user['userId']);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Warning', child: Text("Send Warning")),
                              const PopupMenuItem(value: 'Reject', child: Text("Reject Report")),
                              const PopupMenuItem(value: 'Delete', child: Text("Delete Account")),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.red),
                          ),
                        ),
                      ),
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