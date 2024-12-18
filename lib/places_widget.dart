import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookmark_service.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory; 
  Places_widget({this.placeIds,this.filterCategory}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PlacesList(placeIds: placeIds,filterCategory: filterCategory), 
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
    return StreamBuilder<QuerySnapshot>(
      stream: placeIds != null && placeIds!.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('places')
              .where(FieldPath.documentId, whereIn: placeIds) 
              .where(
                'category',
                isEqualTo: filterCategory != null && filterCategory != "All Categories"
                    ? filterCategory
                    : null,
              ) 
              .orderBy('created_at', descending: true)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('places')
              .where(
                'category',
                isEqualTo: filterCategory != null && filterCategory != "All Categories"
                    ? filterCategory
                    : null,
              ) 
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
              String placeId = doc.id;
              String placeName = doc['place_name'];
              String category = doc['category'];

              return StreamBuilder<bool>(
                stream: BookmarkService().bookmarkStream(placeId, 'places'),
                builder: (context, bookmarkSnapshot) {
                  bool isBookmarked = bookmarkSnapshot.data ?? false;

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
                            child: Container(
                              width: 150,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                image: DecorationImage(
                                  image: imageUrl.isNotEmpty
                                      ? (Uri.tryParse(imageUrl)?.isAbsolute == true
                                          ? NetworkImage(imageUrl) as ImageProvider<Object>
                                          : AssetImage(imageUrl) as ImageProvider<Object>)
                                      : AssetImage('images/place_default_image.png'), 
                                  fit: BoxFit.cover,
                                ),
                              ),
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
                          IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Color(0xFF800020) : Colors.grey,
                            ),
                            onPressed: () async {
                              print('Toggling bookmark for place: $placeId');
                              await BookmarkService().toggleBookmark(placeId, 'places'); 
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