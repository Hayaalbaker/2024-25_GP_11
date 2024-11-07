import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlacesList(), 
    );
  }
}

class PlacesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView(
            children: documents.map((doc) {
              String imageUrl = doc['imageUrl'] ?? ''; // Assuming 'image_url' is in Firestore
              return Card(
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image, size: 50), // Placeholder if image is missing
                  title: Text(doc['place_name']),
                  subtitle: Text(doc['category']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewPlace(place_Id: doc.id),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
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
