import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookmark_service.dart';
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
  final String? filterCategory;

  PlacesList({this.placeIds, this.filterCategory});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('places');

    if (filterCategory != null && filterCategory != "All Categories") {
      query = query.where('category', isEqualTo: filterCategory);
    }

    if (placeIds != null && placeIds!.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereIn: placeIds);
    }

    query = query.orderBy('created_at', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              var doc = documents[index];
              String imageUrl = doc['imageUrl'] ?? '';
              String placeId = doc.id;
              String placeName = doc['place_name'];
              String category = doc['category'];

              return FutureBuilder<bool>(
                future: BookmarkService().isBookmarked(placeId),
                builder: (context, bookmarkSnapshot) {
                  bool isBookmarked = bookmarkSnapshot.data ?? false;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewPlace(place_Id: placeId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Hero(
                            tag: placeId,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 200,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/placeholder.png',
                                      width: 200,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? Color(0xFF800020)
                                  : Colors.grey,
                            ),
                            onPressed: () async {
                              await BookmarkService().toggleBookmark(placeId);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}