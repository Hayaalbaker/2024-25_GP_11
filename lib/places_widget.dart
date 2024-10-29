import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // <1> Use StreamBuilder

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 230, 230, 230),
          bottom: PreferredSize(
            preferredSize: Size(200.0, 25.0),
            child: SizedBox(
              width: 200.0,
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.add_location_alt),
                    text: "Places",
                  ),
                  Tab(
                    icon: Icon(Icons.rate_review),
                    text: "Reviews",
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            PlacesWidget(),
            Center(
              child: Text("Reviews"),
            ),
          ],
        ),
      ),

      // Use Expanded to take full height for the pages
    );
  }
}

class PlacesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // <1> Use StreamBuilder
    int itemCount = 6;
    return StreamBuilder<QuerySnapshot>(
        // <2> Pass `Stream<QuerySnapshot>` to stream
        stream: FirebaseFirestore.instance
            .collection('places')
            .orderBy('created_at', descending: true) // Ordering by timestamp
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // <3> Retrieve `List<DocumentSnapshot>` from snapshot
            final List<DocumentSnapshot> documents = snapshot.data!.docs;
            return ListView(
              children: documents
                  .map((doc) => Card(
                        child: ListTile(
                          title: Text(doc['place_name']),
                          subtitle: Text(doc['category']),
                          onTap: () {
                            // Use onTap instead of onPressed
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewPlace(
                                    place_Id: doc.id), // Ensure the parameter name matches
                              ),
                            );
                          },
                        ),
                      ))
                  .toList(),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Text("Empty..");
          }
        });
  }
}
