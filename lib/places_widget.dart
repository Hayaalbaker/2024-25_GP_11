import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory; // Added category filter
  Places_widget({this.placeIds,this.filterCategory}); // Updated constructor

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PlacesList(placeIds: placeIds,filterCategory: filterCategory), // Pass placeIds to PlacesList
        ),
      ),
    );
  }
}

class PlacesList extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory; // Added category filter
  PlacesList({this.placeIds,this.filterCategory}); // Constructor to accept placeIds

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
stream: placeIds != null && placeIds!.isNotEmpty
    ? FirebaseFirestore.instance
        .collection('places')
        .where(FieldPath.documentId,
            whereIn: placeIds) // Filter by placeIds
        .where(
          'category',
          isEqualTo: filterCategory != null && filterCategory != "All Categories" 
              ? filterCategory 
              : null,
        ) // Add category filter dynamically
        .orderBy('created_at', descending: true)
        .snapshots()
    : FirebaseFirestore.instance
        .collection('places')
        .where(
          'category',
          isEqualTo: filterCategory != null && filterCategory != "All Categories" 
              ? filterCategory 
              : null,
        ) // Add category filter dynamically
        .orderBy('created_at', descending: true)
        .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var doc = documents[index];
              String imageUrl = doc['imageUrl'] ?? '';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewPlace(place_Id: doc.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Hero(
                        tag: doc.id,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.asset(
                                  imageUrl,
                                  width: 200,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.image, size: 150),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['place_name'],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              doc['category'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(child: Text("No places available."));
        }
      },
    );
  }
}