import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localize/main.dart';
import 'bookmark_service.dart';
import 'view_Place.dart';

class PlacesList extends StatefulWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  PlacesList({this.placeIds, this.filterCategory});

  @override
  _PlacesListState createState() => _PlacesListState();
}

class PlacesWidget extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  PlacesWidget({this.placeIds, this.filterCategory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PlacesList(placeIds: placeIds, filterCategory: filterCategory),
        ),
      ),
    );
  }
}

class _PlacesListState extends State<PlacesList> {
  List<String> userInterests = [];
  List<Map<String, dynamic>> recommendedPlaces = [];

  @override
  void initState() {
    super.initState();
    _fetchRecommendedPlaces();
  }

  Future<void> _fetchRecommendedPlaces() async {
    try {
      List<Map<String, dynamic>> places = await sendUserIdToServer();

      debugPrint("✅ Retrieved data from the server: $places");

      if (!mounted) return;
      setState(() {
        recommendedPlaces = places;
      });
    } catch (e) {
      debugPrint("❌ Error while fetching recommendations: $e");
    }
  }

  Future<List<Map<String, dynamic>>> sendUserIdToServer() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final url = Uri.parse('http://10.0.2.2:5000/api/receiveUserId');
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json", "Connection": "close"},
        body: jsonEncode({"userId": user.uid}),
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException("⏳ Server did not respond in time.");
      });

      debugPrint("📥 Server response: ${response.statusCode}");
      debugPrint("📤 Raw response body: ${response.body}");

      try {
        final data = jsonDecode(response.body);
        if (data is! Map || !data.containsKey('recommendations')) {
          debugPrint("⚠️ Invalid JSON format");
          return [];
        }
        return List<Map<String, dynamic>>.from(data['recommendations']);
      } catch (e) {
        debugPrint("❌ JSON parsing error: $e");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Error while connecting to the server: $e");
      return [];
    }
  }

  Query _getPlacesQuery() {
    Query placesQuery = FirebaseFirestore.instance.collection('places');

    if (widget.filterCategory != null &&
        widget.filterCategory != "All Categories") {
      placesQuery =
          placesQuery.where('category', isEqualTo: widget.filterCategory);
    }

    return placesQuery.orderBy('created_at', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: recommendedPlaces.length,
            itemBuilder: (context, index) {
              var place = recommendedPlaces[index];
              return _buildPlaceItem(
                context,
                place['id'] ?? 'unknown_id',
                place['place_name'] ?? 'Unknown Place',
                place['category'] ?? 'Unknown Category',
                place['imageUrl'] ?? '',
              );
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getPlacesQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('❌ Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('⚠️ No available places.'));
              }

              final List<DocumentSnapshot> documents = snapshot.data!.docs;
              return ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  var doc = documents[index];
                  if (!doc.exists) return const SizedBox();

                  return _buildPlaceItem(
                    context,
                    doc.id,
                    doc['place_name'] ?? 'Unknown Place',
                    doc['category'] ?? 'Unknown Category',
                    doc['imageUrl'] ?? '',
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceItem(
    BuildContext context,
    String placeId,
    String placeName,
    String category,
    String imageUrl,
  ) {
    if (placeId.isEmpty) {
      debugPrint("⚠️ Skipping item due to empty placeId!");
      return const SizedBox();
    }

    return StreamBuilder<bool>(
      stream: BookmarkService().bookmarkStream(placeId, 'places'),
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
                  child: Container(
                    width: 150,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                        image: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : const AssetImage('images/place_default_image.png')
                                as ImageProvider,
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
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? const Color(0xFF800020) : Colors.grey,
                  ),
                  onPressed: () async {
                    await BookmarkService().toggleBookmark(placeId, 'places');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
