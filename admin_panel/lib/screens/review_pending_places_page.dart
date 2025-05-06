import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PlaceDetailsPage.dart';

class ReviewPendingPlacesPage extends StatefulWidget {
  const ReviewPendingPlacesPage({super.key});

  @override
  State<ReviewPendingPlacesPage> createState() =>
      _ReviewPendingPlacesPageState();
}

class _ReviewPendingPlacesPageState extends State<ReviewPendingPlacesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot> getPendingPlacesStream() {
    return FirebaseFirestore.instance.collection('pending_places').snapshots();
  }

  Stream<QuerySnapshot> getApprovedPlacesStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .limit(100)
        .snapshots();
  }

  Future<void> approvePlace(DocumentSnapshot doc) async {
    if (!mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(doc.id)
          .set(doc.data() as Map<String, dynamic>);
      await doc.reference.delete();
      await FirebaseFirestore.instance.collection('Notifications').add({
        'receiverUid': doc['user_uid'],
        'message':
            'Your place "${doc['place_name']}" has been approved and added.',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place Approved and moved to Places')),
      );
    } catch (e) {
      print('Error approving place: $e');
    }
  }

  void rejectPlace(DocumentSnapshot doc) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.close, color: Colors.red),
              SizedBox(width: 8),
              Text('Reject Place'),
            ],
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Cancel'),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('rejected_places')
                    .doc(doc.id)
                    .set({
                  ...doc.data() as Map<String, dynamic>,
                  'rejection_reason': reasonController.text,
                });
                await doc.reference.delete();
                await FirebaseFirestore.instance
                    .collection('Notifications')
                    .add({
                  'receiverUid': doc['user_uid'],
                  'message':
                      '❌ Your place "${doc['place_name']}" was rejected. Reason: ${reasonController.text}',
                  'isRead': false,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Place Rejected')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlaceCard(DocumentSnapshot doc, {required bool showActions}) {
    final data = doc.data() as Map<String, dynamic>;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlaceDetailsPage(placeData: data)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: showActions
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              child: Icon(
                showActions ? Icons.assignment_turned_in : Icons.verified,
                color: showActions ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['place_name'] ?? 'Unnamed',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!showActions)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Approved',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    data['category'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (showActions)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => approvePlace(doc),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => rejectPlace(doc),
                    tooltip: 'Reject',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Review Pending Places')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Approved Places',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: isSearching
                  ? getApprovedPlacesStream()
                  : getPendingPlacesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No places found.'));
                }

                final docs = isSearching
                    ? snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final placeName =
                            data['place_name']?.toString().toLowerCase() ?? '';
                        return placeName.contains(_searchQuery);
                      }).toList()
                    : snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No matching places found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return buildPlaceCard(docs[index],
                        showActions: !isSearching);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}