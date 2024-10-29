// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
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
  // String placeId='0';
    //_PlaceScreenState() : super(placeId: "12345");

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _placeName = '';
  String _description = 'description'; // Default values to avoid null issues
  String _location = 'location';
  String _category = 'category';
  String _subcategory = 'subcategory';
  //Timestamp _created_at ; // Default values to avoid null issues
  String _neighborhood = 'Neighborhood';
  String _street = 'Street';


  @override
  void initState() {
    super.initState();
    _loadPlaceProfile();
  }

  void _loadPlaceProfile() async {
   // place? place = _auth.currentUser;
    //if (place != null) {
      try {
          String placeId = widget.place_Id;
        DocumentSnapshot placeDoc =
            await _firestore.collection('places').doc(placeId).get();
        if (placeDoc.exists) {
          setState(() {
            var data = placeDoc.data() as Map<String, dynamic>;
            _placeName =   data['place_name'];
            _description = data['description'] ?? ' description';
            _location = data['location'] ?? 'location';
            _category =   data['category'] ?? 'category';
            _subcategory =   data['subcategory'];
          //  _created_at =   data['created_at'];
            _neighborhood =   data['Neighborhood'];
            _street =   data['Street'];
          });
        }
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
   // }
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
 // Format the date
    //final String formattedDate = _created_at;

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
            _buildDetailItem("Place Name:", _placeName),
            _buildDetailItem("Description:", _description),
            _buildDetailItem("Category:", _category),
            _buildDetailItem("Subcategory:", _subcategory),
            _buildDetailItem("Neighborhood:", _neighborhood),
            _buildDetailItem("Street:", _street),
         //   _buildDetailItem("Created At:", formattedDate),
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
          Expanded(child: Text(value,  style: TextStyle(fontSize: 18),) ),
        ],
      ),
    );
  }

  // Widget for the location link
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
   Flexible( // Use Flexible to allow wrapping
            child: GestureDetector(
              onTap: () => _launchLocation(url),
              child: Text(
                url,
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                softWrap: true, // Ensure text wraps
                overflow: TextOverflow.visible, // Handle overflow
              ),
            ),
          ),
        ],
      ),
    );
  }



}
