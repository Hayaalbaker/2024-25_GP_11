import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  Future<void> markAsResolved(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'Status': 'Resolved',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Text("Reviews", style: Theme.of(context).textTheme.headlineSmall),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('Status', isEqualTo: 'Pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text("No pending reviews available.");
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: ${data['Report_Type'] ?? 'Unknown'}"),
                            Text("Status: ${data['Status']}"),
                            Text("Reported By: ${data['ReportedBy']}"),
                            FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('Review')
      .doc(data['Review_ID'])
      .get(),
  builder: (context, reviewSnapshot) {
    if (reviewSnapshot.connectionState == ConnectionState.waiting) {
      return const Text("Loading review...");
    }

    if (!reviewSnapshot.hasData || !reviewSnapshot.data!.exists) {
      return const Text("Review not found.");
    }

    final reviewData = reviewSnapshot.data!.data() as Map<String, dynamic>;
    final reviewText = reviewData['Text'] ?? 'No text provided';

    return Text("Review Text: $reviewText");
  },
),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => markAsResolved(docId),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Mark Resolved'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}