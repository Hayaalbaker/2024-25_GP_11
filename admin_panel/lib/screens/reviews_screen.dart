import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';
import 'package:admin_panel/utils/warning_service.dart';


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
                      await WarningService.sendWarning(context, reviewOwnerId, reportId);
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
  final dataMap = doc.data() as Map<String, dynamic>;

  if (dataMap['Report_Target_Type'] != 'Review') continue;

  if (!dataMap.containsKey('Review_ID')) continue;

  final reviewId = dataMap['Review_ID'];
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