import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlacesList(), // Display the PlacesList widget
    );
  }
}

class PlacesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .orderBy('created_at', descending: true) // Ordering by timestamp
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          return ListView(
            children: documents.map((doc) => Card(
              child: ListTile(
                title: Text(doc['place_name']),
                subtitle: Text(doc['category']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewPlace(
                        place_Id: doc.id, // Ensure the parameter name matches
                      ),
                    ),
                  );
                },
              ),
            )).toList(),
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
