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
  String? placeId;
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
    placeId = widget.place_Id; // Assign the passed placeId to the local placeId variable.
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPlaceProfile();
  }

void _launchLocation(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void _loadPlaceProfile() async {
  if (placeId == null || placeId!.isEmpty) {
    // If placeId is null or empty, show an error message and return early.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid place ID.')),
      );
    });
    return; // Exit the method if placeId is invalid.
  }

  try {
    debugPrint('here  ViewPlace');
    debugPrint('here  placeId: $placeId');
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
    } else {
      // Handle case where the document doesn't exist.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Place not found.')),
        );
      });
    }
  } catch (e) {
    // Handle any errors that occur during Firestore query.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    });
  }
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    _buildDetailItem("", _description),
                    _buildDetailItem("Category:", _category),
                    _buildDetailItem("Subcategory:", _subcategory),
                    _buildDetailItem("Neighborhood:", _neighborhood),
                    _buildDetailItem("Street:", _street),
                    _buildLocationLink("Location:", _location),
                  ],
                ),
              ),
              // Pass placeId to the Review_widget here
              Review_widget(place_Id: placeId),  // Ensure the correct placeId is passed
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