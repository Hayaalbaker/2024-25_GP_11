import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewPlace extends StatefulWidget {
  @override
  final String place_Id; // Declare the final property

  // Constructor with required parameter
  const ViewPlace({super.key, required this.place_Id});
 // placeId = ModalRoute.of(context)!.settings.arguments as String;
  @override
  _PlaceScreenState createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<ViewPlace> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _placeName = '';
  String _description = 'description';
  String _location = 'location';
  String _category = 'category';
  String _subcategory = 'subcategory';
  String _neighborhood = 'Neighborhood';
  String _street = 'Street';
  String _imageUrl = ''; // To store the image URL

  @override
  void initState() {
    super.initState();
    _loadPlaceProfile();
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
          _imageUrl = data['imageUrl'] ?? ''; // Get the image URL
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
        title: Text("Place Details"),
      ),
      backgroundColor: const Color.fromARGB(255, 239, 215, 215),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageUrl.isNotEmpty
                ? Image.network(_imageUrl) // Display the image if available
                : Icon(Icons.image, size: 150), // Placeholder if no image
            SizedBox(height: 16),
            _buildDetailItem("Place Name:", _placeName),
            _buildDetailItem("Description:", _description),
            _buildDetailItem("Category:", _category),
            _buildDetailItem("Subcategory:", _subcategory),
            _buildDetailItem("Neighborhood:", _neighborhood),
            _buildDetailItem("Street:", _street),
            _buildLocationLink("Location:", _location),
          ],
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 18))),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Flexible(
            child: GestureDetector(
              onTap: () => _launchLocation(url),
              child: Text(
                url,
                style: TextStyle(
                  color: Colors.blue,
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