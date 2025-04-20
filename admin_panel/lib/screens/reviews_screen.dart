import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String selectedStatus = 'All';
  final statusOptions = ['All', 'Pending', 'Rejected', 'Deleted', 'Warning Sent'];

  Stream<QuerySnapshot> getReportsStream() {
    final ref = FirebaseFirestore.instance.collection('reports');
    return selectedStatus == 'All'
        ? ref.orderBy('Report_Date', descending: true).snapshots()
        : ref.where('Status', isEqualTo: selectedStatus).orderBy('Report_Date', descending: true).snapshots();
  }

  Widget statusBadge(String status) {
    final lower = status.toLowerCase();
    Color color = lower.contains('resolved')
        ? Colors.green
        : lower.contains('pending')
            ? Colors.orange
            : lower.contains('rejected')
                ? Colors.red
                : lower.contains('deleted')
                    ? Colors.grey
                    : lower.contains('warning')
                        ? Colors.amber
                        : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> showWarningDialog(String userId, String reportId) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Warning"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter warning..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;

              final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
              final userEmail = userDoc['email'] ?? 'No email';
              final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';

              await FirebaseFirestore.instance.collection('warnings').add({
                'userId': userId,
                'userEmail': userEmail,
                'message': message,
                'date': FieldValue.serverTimestamp(),
              });

              await http.post(
                Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
                headers: {'origin': 'http://localhost', 'Content-Type': 'application/json'},
                body: json.encode({
                  'service_id': 'service_5lj8e5w',
                  'template_id': 'template_0qns40h',
                  'user_id': '0tNpevs6M08p6KJEJ',
                  'template_params': {'to_email': userEmail, 'message': message}
                }),
              );

              await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                'Status': 'Warning Sent',
                'ReviewedBy': adminEmail,
              });

              Navigator.pop(context);
            },
            child: const Text("Send"),
          )
        ],
      ),
    );
  }

  Widget buildReportCard(Map<String, dynamic> data, String reviewText, String reportedBy, int count, String? reviewer, String reportId, String reviewOwnerId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Text("Type: ${data['Report_Type'] ?? 'Unknown'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (data['Status'] != null) statusBadge(data['Status']),
              ],
            ),
            const SizedBox(height: 8),
            if (data['Report_Description']?.toString().isNotEmpty == true)
              Text("Description: ${data['Report_Description']}"),
            Text("Reported By: $reportedBy"),
            Text("Review Text: $reviewText"),
            Text("Number of Reports: $count"),
            if (reviewer != null) Text("Resolved By: $reviewer"),
            if (data['Status'] == 'Pending')
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) async {
                    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';

                    if (value == 'Warning') {
                      await showWarningDialog(reviewOwnerId, reportId);
                    } else if (value == 'Reject') {
                      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                        'Status': 'Rejected',
                        'ReviewedBy': adminEmail,
                      });
                    } else if (value == 'Delete') {
                      final deletedReview = await FirebaseFirestore.instance.collection('Review').doc(data['Review_ID']).get();
                      await FirebaseFirestore.instance.collection('Review').doc(data['Review_ID']).delete();
                      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                        'Status': 'Deleted',
                        'ReviewedBy': adminEmail,
                        'ReviewTextBeforeDelete': deletedReview['Review_Text'] ?? '',
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Warning', child: Text("Send Warning")),
                    const PopupMenuItem(value: 'Reject', child: Text("Reject Report")),
                    const PopupMenuItem(value: 'Delete', child: Text("Delete Review")),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader("Reviews"),

        Padding(
          padding: const EdgeInsets.all(24),
          child: DropdownButtonFormField(
            value: selectedStatus,
            decoration: const InputDecoration(labelText: 'Filter by Status', border: OutlineInputBorder()),
            onChanged: (val) => setState(() => selectedStatus = val!),
            items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: getReportsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final grouped = <String, List<QueryDocumentSnapshot>>{};
              for (final doc in snapshot.data!.docs) {
                final reviewId = doc['Review_ID'];
                grouped.putIfAbsent(reviewId, () => []).add(doc);
              }

              final reviewIds = grouped.keys.toList();
              if (reviewIds.isEmpty) return const Center(child: Text("No reports found."));

              return ListView.builder(
                itemCount: reviewIds.length,
                itemBuilder: (context, i) {
                  final reviewId = reviewIds[i];
                  final reports = grouped[reviewId]!;
                  final first = reports.first;
                  final data = first.data() as Map<String, dynamic>;

                  return FutureBuilder(
                    future: Future.wait([
                      FirebaseFirestore.instance.collection('users').doc(data['ReportedBy']).get(),
                      FirebaseFirestore.instance.collection('Review').doc(reviewId).get(),
                    ]),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox();
                      final email = snap.data![0]['email'] ?? 'Unknown';
                      final reviewDoc = snap.data![1];
                      final reviewText = reviewDoc.exists
                          ? reviewDoc['Review_Text'] ?? 'No text'
                          : data['ReviewTextBeforeDelete'] ?? 'Review deleted';
                      final reviewOwnerId = reviewDoc.exists ? reviewDoc['user_uid'] : 'Unknown';

                      return buildReportCard(
                        data,
                        reviewText,
                        email,
                        reports.length,
                        data['ReviewedBy'],
                        first.id,
                        reviewOwnerId,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}