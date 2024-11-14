import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(CreatePostPage());
}

class CreatePostPage extends StatelessWidget {
  final String? placeId;

  CreatePostPage({super.key, this.placeId}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post a Review',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReviewForm(placeId: placeId), 
    );
  }
}

class ReviewForm extends StatefulWidget {
  final String? placeId;

  ReviewForm({super.key, required this.placeId}); // Constructor now accepts a nullable String

  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  String ReviewText = '';
  List<String> LikeCount = [];
  int Rating = 1;
  String user_uid = '';
  final TextEditingController _reviewController = TextEditingController();

  bool isLoading = false;
  List<Map<String, String>> places = [];
  String? selectedPlaceName;
  String? selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchPlaces();

    // If placeId is passed, pre-fill the dropdown
    if (widget.placeId != null) {
      selectedPlaceId = widget.placeId;
      final place = places.firstWhere((place) => place['id'] == selectedPlaceId, orElse: () => {});
      if (place.isNotEmpty) {
        selectedPlaceName = place['name'];
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        user_uid = user.uid;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load user data: $e'),
      ));
    }
  }

  Future<void> fetchPlaces() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('places').get();
      setState(() {
        places = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['place_name'] as String,
          };
        }).toList();
        
        // After places are fetched, pre-fill the selected place if a placeId is provided
        if (widget.placeId != null && places.isNotEmpty) {
          final place = places.firstWhere(
            (place) => place['id'] == widget.placeId, 
            orElse: () => {}
          );
          if (place.isNotEmpty) {
            selectedPlaceId = widget.placeId;
            selectedPlaceName = place['name'];
          }
        }
      });
    } catch (e) {
      print('Error fetching places: $e');
    }
  }

  Future<void> saveReview() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        DocumentReference newReviewRef = FirebaseFirestore.instance.collection('Review').doc();

        await newReviewRef.set({
          'Review_Text': ReviewText,
          'user_uid': user_uid,
          'placeId': selectedPlaceId, // Use the selectedPlaceId
          'Rating': Rating,
          'Post_Date': FieldValue.serverTimestamp(),
          'Like_count': LikeCount,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Review posted successfully!'),
        ));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post a Review"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: 'Write your review',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 20),
              RatingBar.builder(
                initialRating: Rating.toDouble(),
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    Rating = rating.toInt();
                  });
                },
              ),
              DropdownButton<String>(
                hint: Text("Select a place"),
                value: selectedPlaceName,
                onChanged: (value) {
                  setState(() {
                    selectedPlaceName = value;
                    selectedPlaceId = places
                        .firstWhere((place) => place['name'] == value)['id'];
                  });
                },
                items: places.map((place) {
                  return DropdownMenuItem<String>(
                    value: place['name'],
                    child: Text(place['name']!),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ReviewText = _reviewController.text;
                  saveReview();
                },
                child: Text('Post Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}