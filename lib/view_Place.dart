import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bookmark_service.dart';
import 'create_post_page.dart';
import 'review_widget.dart';
import 'package:rating_summary/rating_summary.dart';

class ViewPlace extends StatefulWidget {
  final String place_Id;

  const ViewPlace({super.key, required this.place_Id});

  @override
  _PlaceScreenState createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<ViewPlace>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? placeId;
  String _placeName = '';
  String _description = 'description';
  String _location = 'location';
  String _category = 'category';
  String _subcategory = 'subcategory';
  String _neighborhood = 'Neighborhood';
  String _street = 'Street';
  String _imageUrl = '';
  bool isBookmarked = false;
  int _totalReviews = 0;
  double _averageRating = 0.0;
  int _countFiveStars = 0;
  int _countFourStars = 0;
  int _countThreeStars = 0;
  int _countTwoStars = 0;
  int _countOneStars = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    placeId = widget.place_Id;
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaceProfile();
    _checkIfBookmarked();
    _fetchRatingSummary();
  }

  Future<void> _loadPlaceProfile() async {
    if (placeId == null || placeId!.isEmpty) {
      // If placeId is null or empty, show an error message and return early.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid place ID.'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
        );
      });
      return; // Exit the method if placeId is invalid.
    }

    try {
      DocumentSnapshot placeDoc =
          await _firestore.collection('places').doc(placeId).get();
      if (placeDoc.exists) {
        setState(() {
          var data = placeDoc.data() as Map<String, dynamic>;
          _placeName = data['place_name'];
          _description = data['description'] ?? 'description';
          _location = data['location'] ?? 'location';
          _category = data['category'] ?? 'category';
          _subcategory = data['subcategory'] ?? 'subcategory';
          _neighborhood = data['Neighborhood'] ?? 'Neighborhood';
          _street = data['Street'] ?? 'Street';
          _imageUrl = data['imageUrl'] ?? '';
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Place not found.'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
          );
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
        );
      });
    }
  }

  Future<void> _launchLocation(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _checkIfBookmarked() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null && placeId != null) {
      final docSnapshot = await _firestore
          .collection('bookmarks')
          .doc(userId)
          .collection('places')
          .doc(placeId)
          .get();

      setState(() {
        isBookmarked = docSnapshot.exists;
      });
    }
  }

  Future<void> toggleBookmarkForPlace() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || placeId == null) return;

    final placeRef = _firestore
        .collection('bookmarks')
        .doc(userId)
        .collection('places')
        .doc(placeId);

    try {
      if (isBookmarked) {
        await placeRef.delete();
        setState(() {
          isBookmarked = false;
        });
      } else {
        await placeRef.set({'timestamp': FieldValue.serverTimestamp()});
        setState(() {
          isBookmarked = true;
        });
      }
    } catch (e) {
      print("Error toggling bookmark: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update bookmark"),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),));
    }
  }

  void _fetchRatingSummary() async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('Review')
          .where('placeId', isEqualTo: widget.place_Id)
          .get();

      int totalReviews = reviewsSnapshot.docs.length;
      int totalRatingSum = 0;
      int countFiveStars = 0;
      int countFourStars = 0;
      int countThreeStars = 0;
      int countTwoStars = 0;
      int countOneStars = 0;

      for (var doc in reviewsSnapshot.docs) {
        int rating = doc['Rating'];
        totalRatingSum += rating;
        switch (rating) {
          case 5:
            countFiveStars++;
          case 4:
            countFourStars++;
          case 3:
            countThreeStars++;
          case 2:
            countTwoStars++;
          case 1:
            countOneStars++;
          default:
            break;
        }
      }

      double averageRating =
          totalReviews > 0 ? totalRatingSum / totalReviews : 0.0;

      setState(() {
        _totalReviews = totalReviews;
        _averageRating = averageRating;
        _countFiveStars = countFiveStars;
        _countFourStars = countFourStars;
        _countThreeStars = countThreeStars;
        _countTwoStars = countTwoStars;
        _countOneStars = countOneStars;
      });
    } catch (e) {
      print("Failed to fetch rating summary: $e");
      //show a SnackBar or other UI ???
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_placeName),
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF800020),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _imageUrl.isNotEmpty
              ? Image.asset(
                  _imageUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                ),)
              : Icon(
                  Icons.image,
                  size: 150,
                  color: Colors.grey,
                ),
          SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Reviews"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingSummary(
                        counter: _totalReviews,
                        average:
                            double.parse(_averageRating.toStringAsFixed(1)),
                        counterFiveStars: _countFiveStars,
                        counterFourStars: _countFourStars,
                        counterThreeStars: _countThreeStars,
                        counterTwoStars: _countTwoStars,
                        counterOneStars: _countOneStars,
                      ),
                      SizedBox(height: 20),
                      _buildDetailItem("", _description),
                      _buildDetailItem("Category:", _category),
                      _buildDetailItem("Subcategory:", _subcategory),
                      _buildDetailItem("Neighborhood:", _neighborhood),
                      _buildDetailItem("Street:", _street),
                      _buildLocationLink("Location:", _location),
                    ],
                  ),
                ),
                Review_widget(place_Id: placeId),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Review button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreatePostPage(
                          placeId: placeId ?? '', ISselectplace: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF800020),
                  minimumSize: Size(250, 60),
                  padding: EdgeInsets.symmetric(horizontal: 40),
                ),
                child: Text(
                  "Review $_placeName",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Bookmark icon
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color: isBookmarked ? Color(0xFF800020) : Colors.grey,
                ),
                onPressed: () async {
                  await toggleBookmarkForPlace();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Place bookmarked!'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7)),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLink(String label, String url) {
    String shortenedUrl = url.length > 30 ? '${url.substring(0, 30)}...' : url;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () => _launchLocation(url),
              child: Text(
                shortenedUrl,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
