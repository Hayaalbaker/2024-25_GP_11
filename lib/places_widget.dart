import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'bookmark_service.dart';
import 'view_Place.dart';

class Places_widget extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  Places_widget({this.placeIds, this.filterCategory});

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

class PlacesList extends StatefulWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  PlacesList({this.placeIds, this.filterCategory});

  @override
  _PlacesListState createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  final String googleApiKey = "AIzaSyAx6eDEuqKkXedTk9GdpznubrILROuuVuY"; 
  Map<String, Map<String, dynamic>> googlePlaceData = {};

  @override
  void initState() {
    super.initState();
    _fetchRiyadhPlaces();
  }

  @override
  Widget build(BuildContext context) {
    List<String>? categories;
    if (widget.filterCategory != null && widget.filterCategory != "All Categories") {
      categories = [widget.filterCategory!]; 
    }

Query _getPlacesQuery() {
  Query placesQuery = FirebaseFirestore.instance.collection('places');

  if (widget.filterCategory != null && widget.filterCategory != "All Categories") {
    placesQuery = placesQuery.where('category', isEqualTo: widget.filterCategory);
  }

  return placesQuery.orderBy('created_at', descending: true);
}


return StreamBuilder<QuerySnapshot>(
  stream: _getPlacesQuery().snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      print("🔥 Firestore places count: ${snapshot.data!.docs.length}");
      final List<DocumentSnapshot> documents = snapshot.data!.docs;

      return ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          var doc = documents[index];
          String placeId = doc.id;
          String imageUrl = doc['imageUrl'] ?? '';
          String placeName = doc['place_name'] ?? 'Unknown Place';
          String category = doc['category'] ?? 'Unknown Category';

          print("📍 Firestore Place: $placeName - Category: $category");

          return _buildPlaceItem(context, placeId, placeName, category, imageUrl);
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

  Widget _buildPlaceItem(
      BuildContext context, String placeId, String placeName, String category, String imageUrl) {
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
  }

Future<void> _fetchRiyadhPlaces() async {
  const String apiKey = "AIzaSyAx6eDEuqKkXedTk9GdpznubrILROuuVuY";
  String nextPageToken = "";

  do {
    final String url =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        "?location=24.7136,46.6753"
        "&radius=25000000"
        "&type=restaurant|cafe|bakery|park|amusement_park|shopping_mall|store|supermarket|zoo|aquarium|library"
        "&key=$apiKey"
        "&pagetoken=$nextPageToken";

    try {
      final response = await http.get(Uri.parse(url));
      print("📡 Fetching Riyadh Places...");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'OK') {
          List<dynamic> places = jsonResponse['results'];

          for (var place in places) {
            String placeId = place['place_id'];
            String placeName = place['name'];
            List<dynamic>? types = place['types'];

            print("📍 Found Place: $placeName - Categories: $types"); 

            await _fetchGooglePlaceDetails(placeId);
          }

          nextPageToken = jsonResponse.containsKey("next_page_token")
              ? jsonResponse["next_page_token"]
              : "";

          if (nextPageToken.isNotEmpty) {
            await Future.delayed(Duration(seconds: 2)); 
          }

        } else {
          print("❌ Google API Error: ${jsonResponse['status']}");
          break;
        }
      } else {
        print("❌ HTTP Request Failed: ${response.statusCode}");
        break;
      }
    } catch (e) {
      print("❌ Error Fetching Places: $e");
      break;
    }
  } while (nextPageToken.isNotEmpty);
}
}

Future<void> _fetchGooglePlaceDetails(String placeId) async {
  const String apiKey = "AIzaSyAx6eDEuqKkXedTk9GdpznubrILROuuVuY"; 
  final String url =
      "https://maps.googleapis.com/maps/api/place/details/json"
      "?place_id=$placeId"
      "&key=$apiKey"
      "&fields=name,formatted_address,editorial_summary,types,photos";

  try {
    final response = await http.get(Uri.parse(url));
    print("📡 Fetching place details for: $placeId");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'OK') {
        var result = jsonResponse['result'];

        DocumentSnapshot placeDoc = await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .get();

        if (placeDoc.exists) {
          print("⚠️ Skipping (Already Exists): ${result['name']}");
          return;
        }

        String placeName = result['name'] ?? "Unknown Place";
        String formattedAddress = result['formatted_address'] ?? "Unknown Address";
        String description = result['editorial_summary']?['overview'] ?? "No description available.";
        List<dynamic>? types = result['types'];
        String category = types != null && types.isNotEmpty ? _formatCategory(types[0]) : "Unknown Category";
        String imageUrl = _extractBestPhoto(result['photos']) ?? "";

        var placeDetails = {
          'place_name': placeName,
          'imageUrl': imageUrl,
          'location': formattedAddress,
          'category': category,
          'created_at': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .set(placeDetails);

        print("✅ Added New Place: $placeName - Category: $category");

      } else {
        print("❌ Google API Error: ${jsonResponse['status']}");
      }
    } else {
      print("❌ HTTP Request Failed: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error Fetching Google Place Details: $e");
  }
}

String _formatCategory(String category) {
  Map<String, String> categoryMapping = {
    "meal_delivery": "Restaurant",
    "meal_takeaway": "Restaurant",
    "food": "Restaurant",
    "point_of_interest": "Attraction",
    "store": "Shopping",
    "shopping_mall": "Shopping",
    "bakery": "Bakery",
    "cafe": "Cafe",
    "park": "Park",
    "amusement_park": "Amusement Park",
    "zoo": "Zoo",
    "aquarium": "Aquarium",
    "library": "Library",
    "supermarket": "Supermarket",
  };

  if (categoryMapping.containsKey(category)) {
    return categoryMapping[category]!;
  }

  return category
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String? _extractBestPhoto(List<dynamic>? photos) {
  if (photos != null && photos.isNotEmpty) {
    for (var photo in photos) {
      if (photo.containsKey('photo_reference')) {
        return "https://maps.googleapis.com/maps/api/place/photo"
               "?maxwidth=800"
               "&photoreference=${photo['photo_reference']}"
               "&key=AIzaSyAx6eDEuqKkXedTk9GdpznubrILROuuVuY";  
      }
    }
  }
  return null;  
}
