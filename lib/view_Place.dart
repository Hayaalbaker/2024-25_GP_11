import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'review_widget.dart';

class ViewPlace extends StatefulWidget {
  final String place_Id;

  const ViewPlace({super.key, required this.place_Id});

  @override
  _PlaceScreenState createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<ViewPlace> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _placeName = '';
  String _description = 'description';
  String _location = 'location';
  String _category = 'category';
  String _subcategory = 'subcategory';
  String _neighborhood = 'Neighborhood';
  String _street = 'Street';
  String _imageUrl = '';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaceProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPlaceProfile() async {
    try {
      String placeId = widget.place_Id;
      DocumentSnapshot placeDoc = await _firestore.collection('places').doc(placeId).get();
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    }
  }

  void _launchLocation(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
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
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.image, size: 150, color: Colors.grey),

          SizedBox(height: 16),

          // Tab bar below the image
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Reviews"),
            ],
          ),

          // Expanded TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem("", _description),
                      _buildDetailItem("Category:", _category),
                      _buildDetailItem("Subcategory:", _subcategory),
                      _buildDetailItem("Neighborhood:", _neighborhood),
                      _buildDetailItem("Street:", _street),
                      _buildLocationLink("Location:", _location),
                    ],
                  ),
                ),
                // Reviews Tab with the reusable Review_widget
                // Should be changed later to filer only the place reviews
                Review_widget(),
              ],
            ),
          ),
        ],
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7)),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLink(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () => _launchLocation(url),
              child: Text(
                url,
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