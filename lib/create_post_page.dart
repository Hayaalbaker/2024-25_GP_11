import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'add_place.dart';
import 'home_page.dart';
import 'dart:async';

void main() {
  runApp(CreatePostPage(ISselectplace: false));
}

class CreatePostPage extends StatelessWidget {
  final String? placeId;
  final bool? ISselectplace;

  CreatePostPage({super.key, this.placeId, required this.ISselectplace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post a Review',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ReviewForm(placeId: placeId, ISselectplace: ISselectplace),
    );
  }
}

class ReviewForm extends StatefulWidget {
  final String? placeId;
  final bool? ISselectplace;

  ReviewForm({super.key, required this.placeId, required this.ISselectplace});

  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _placeSearchController = TextEditingController();

  String ReviewText = '';
  int Rating = 0;
  List<String> LikeCount = [];
  String user_uid = '';
  String? selectedPlaceName;
  String? selectedPlaceId;
  String? _placeErrorText;
  String? _ratingErrorText;
  bool ISselectplace = false;

  List<Map<String, String>> _places = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    ISselectplace = widget.ISselectplace ?? false;
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          user_uid = user.uid;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<List<String>> _fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('places')
        .where('place_name', isGreaterThanOrEqualTo: query)
        .where('place_name', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(10)
        .get();

    _places = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['place_name'] as String,
      };
    }).toList();

    return _places.map((place) => place['name']!).toList();
  }

  void _validatePlaceName() {
    setState(() {
      _placeErrorText =
          selectedPlaceName == null ? 'Please select a valid place.' : null;
    });
  }

  void _validateRating() {
    setState(() {
      _ratingErrorText = Rating == 0 ? 'Please select a rating.' : null;
    });
  }

  Future<void> saveReview() async {
    if (selectedPlaceId == null || selectedPlaceId!.isEmpty) {
      setState(() => _placeErrorText = 'Please select a valid place.');
      return;
    }

    if (ReviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a review.')),
      );
      return;
    }

    if (Rating == 0) {
      _validateRating();
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Review').add({
          'Review_Text': ReviewText,
          'user_uid': user_uid,
          'placeId': selectedPlaceId,
          'Rating': Rating,
          'Post_Date': FieldValue.serverTimestamp(),
          'Like_count': LikeCount,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review posted successfully!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting review: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _placeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Post a Review"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            ),
            child: Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _reviewController,
                onChanged: (value) => setState(() => ReviewText = value),
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
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) =>
                    setState(() => Rating = rating.toInt()),
              ),
              if (_ratingErrorText != null)
                Text(_ratingErrorText!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              ISselectplace
                  ? Text('Place: $selectedPlaceName',
                      style: TextStyle(fontSize: 16))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Autocomplete<String>(
                          optionsBuilder:
                              (TextEditingValue textEditingValue) async {
                            return await _fetchPlaceSuggestions(
                                textEditingValue.text);
                          },
                          onSelected: (String selectedPlace) {
                            final foundPlace = _places.firstWhere(
                              (place) => place['name'] == selectedPlace,
                              orElse: () => {'id': '', 'name': ''},
                            );

                            setState(() {
                              selectedPlaceName = foundPlace['name'];
                              selectedPlaceId = foundPlace['id'];
                              _placeErrorText = foundPlace['id']!.isEmpty
                                  ? 'Invalid place selection.'
                                  : null;
                            });
                          },
                          fieldViewBuilder:
                              (context, controller, node, onSubmit) {
                            _placeSearchController.text = controller.text;
                            return TextField(
                              controller: controller,
                              focusNode: node,
                              decoration: InputDecoration(
                                labelText: 'Search for a place',
                                border: OutlineInputBorder(),
                                errorText: _placeErrorText,
                              ),
                            );
                          },
                        ),
                        if (_placeErrorText != null) linktoaddpage(),
                      ],
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _validatePlaceName();
                  _validateRating();
                  if (_formKey.currentState!.validate() &&
                      _placeErrorText == null) {
                    saveReview();
                  }
                },
                child: Text('Submit Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget linktoaddpage() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlacePage()),
          ),
          child: Text(
            'Go to Add Place Page.',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}