import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localize/main.dart';
import 'bookmark_service.dart';
import 'view_Place.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlacesWidget extends StatelessWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  const PlacesWidget({Key? key, this.placeIds, this.filterCategory})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: PlacesList(
            placeIds: placeIds,
            filterCategory: filterCategory,
          ),
        ),
      ),
    );
  }
}

class PlacesList extends StatefulWidget {
  final List<String>? placeIds;
  final String? filterCategory;

  const PlacesList({Key? key, this.placeIds, this.filterCategory})
      : super(key: key);

  @override
  _PlacesListState createState() => _PlacesListState();
}

class _PlacesListState extends State<PlacesList> {
  List<String> userInterests = [];
  List<Map<String, dynamic>> recommendedPlaces = [];
  Timer? _debounce;
  int currentPage = 1;
  bool hasMoreData = true; // To track if there are more pages to load
  int totalRecommendations = 0; // To store the total number of recommendations

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          recommendedPlaces.clear();
        });
        _fetchUserInterests();
      }
    });
    _fetchUserInterests();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('interests')) {
        setState(() {
          userInterests = List<String>.from(userDoc['interests'] ?? []);
        });
      }
      await _fetchRecommendedPlaces();
    } catch (e) {
      debugPrint("❌ Error fetching user interests: $e");
    }
  }

  Future<List<Map<String, dynamic>>> sendUserIdToServer({int page = 1}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    int retries = 0;
    while (retries < 2) {
      try {
        final response = await http.post(
          Uri.parse('http://192.168.100.21:5000/api/receiveUserId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': user.uid,
            'filterCategory': widget.filterCategory ?? "All Categories",
            'page': page,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          totalRecommendations =
              data['total'] ?? 0; // Storing the total recommendations count
          debugPrint("📡 Server Data: ${response.body}");
          return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
        } else {
          debugPrint("❌ Server error: ${response.statusCode}");
          return [];
        }
      } catch (e) {
        retries++;
        debugPrint("❌ Connection error (attempt $retries): $e");
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return [];
  }

  Future<void> _fetchRecommendedPlaces({int page = 1}) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        debugPrint("⏳ Fetching recommended places from server...");
        List<Map<String, dynamic>> recommendations =
            await sendUserIdToServer(page: page);

        List<Map<String, dynamic>> filteredPlaces = [];

        if (widget.filterCategory == null ||
            widget.filterCategory == "All Categories") {
          filteredPlaces = recommendations;
        } else {
          String selectedCategory =
              widget.filterCategory?.trim().toLowerCase() ?? "";
          List<String> validCategories =
              selectedCategory.split(',').map((cat) => cat.trim()).toList();

          for (var recommendation in recommendations) {
            String placeCategory =
                (recommendation['category'] as String?)?.trim().toLowerCase() ??
                    "";
            if (validCategories.any((cat) => placeCategory.contains(cat))) {
              filteredPlaces.add(recommendation);
            }
          }
        }

        if (mounted) {
          setState(() {
            if (page == 1) {
              recommendedPlaces = filteredPlaces;
            } else {
              recommendedPlaces.addAll(filteredPlaces);
            }

            if (filteredPlaces.isEmpty ||
                recommendedPlaces.length >= totalRecommendations) {
              hasMoreData = false;
            }
          });
        }

        debugPrint("✅ Fetched ${filteredPlaces.length} places from page $page");
        debugPrint(
            "📊 Total shown: ${recommendedPlaces.length} / $totalRecommendations");
      } catch (e) {
        debugPrint("❌ Error fetching recommendations: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
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
          if (hasMoreData)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  currentPage++;
                  _fetchRecommendedPlaces(page: currentPage);
                },
                child: const Text("Load More"),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text("No more results", style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(
    BuildContext context,
    String placeId,
    String placeName,
    String category,
    String imageUrl,
  ) {
    if (placeId.isEmpty) return const SizedBox();

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
                            ? CachedNetworkImageProvider(imageUrl)
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