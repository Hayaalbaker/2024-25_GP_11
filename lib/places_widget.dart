import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Places_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // <1> Use StreamBuilder

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 228, 189, 215),
                   bottom: new PreferredSize(
            preferredSize: new Size(200.0, 25.0),
            child: new Container(
              width: 200.0,
              child: new TabBar(
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
    int item_Count = 6;
    return StreamBuilder<QuerySnapshot>(
        // <2> Pass `Stream<QuerySnapshot>` to stream
        stream: FirebaseFirestore.instance.collection('places').snapshots(),
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
                          ),
                        ))
                    .toList());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return Text("Empty..");
          }
        });
  }
}
