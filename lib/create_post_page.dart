import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'add_place.dart'; // Import the Add Place page
void main() {
  runApp(CreatePostPage(
    //placeId: null, 
    ISselectplace: false, 
  ));
}

class CreatePostPage extends StatelessWidget {
  final String? placeId;
final bool? ISselectplace;
  CreatePostPage({super.key, this.placeId, required this.ISselectplace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post a Review',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReviewForm(placeId: placeId, ISselectplace: ISselectplace),
    );
  }
}

class ReviewForm extends StatefulWidget {
  final String? placeId;
final bool? ISselectplace;
  ReviewForm(
      {super.key,
      required this.placeId, required this.ISselectplace}); // Constructor now accepts a nullable String

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
 bool ISselectplace=false;
  bool isLoading = false;
  List<Map<String, String>> places = [];
  String? selectedPlaceName;
  String? selectedPlaceId;


final TextEditingController _placeController = TextEditingController();
String? _placeErrorText;
 @override
void initState() {
  super.initState();
  _loadUserData();
  ISselectplace = widget.ISselectplace ?? false;
  fetchPlaces().then((_) {
    // pre-fill
    if (widget.placeId != null && places.isNotEmpty) {
      final place = places.firstWhere(
        (place) => place['id'] == widget.placeId,
        orElse: () => {},
      );
      if (place.isNotEmpty) {
        setState(() {
          selectedPlaceId = widget.placeId;
          selectedPlaceName = place['name'];
        });
      }
    }
  });
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
    final querySnapshot =
        await FirebaseFirestore.instance.collection('places').get();
    setState(() {
      places = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['place_name'] as String,
        };
      }).toList();
    });
  } catch (e) {
    print('Error fetching places: $e');
  }
}

  Future<void> saveReview() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        DocumentReference newReviewRef =
            FirebaseFirestore.instance.collection('Review').doc();

        await newReviewRef.set({
          'Review_Text': ReviewText,
          'user_uid': user_uid,
          'placeId': selectedPlaceId, // Use selectedPlaceId
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to post review: $e')));
      }
    }
  }



void _validatePlaceSelection() {
  if (selectedPlaceName == null || !places.any((place) => place['name'] == selectedPlaceName)) {
    setState(() {
      _placeErrorText = 'Please select a valid place from the list.';
    });
  } else {
    setState(() {
      _placeErrorText = null; // Clear error if valid
    });
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _reviewController,
              onChanged: (value) {
                setState(() {
                  ReviewText = value;
                });
              },
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
            SizedBox(height: 20),
            ISselectplace
                ? Text(
                    'Place: $selectedPlaceName',
                    style: TextStyle(fontSize: 16),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return places
                              .map((place) => place['name']!)
                              .where((name) => name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selectedPlace) {
                          setState(() {
                            selectedPlaceName = selectedPlace;
                            selectedPlaceId = places.firstWhere(
                                (place) =>
                                    place['name'] == selectedPlace)['id'];
                            _placeErrorText = null; // Clear error
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Search for a place',
                              border: OutlineInputBorder(),
                              hintText: 'Enter a place name',
                              errorText: _placeErrorText,
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  _placeErrorText =
                                      'Place name cannot be empty.';
                                  selectedPlaceName = null;
                                  selectedPlaceId = null;
                                } else if (!places.any(
                                    (place) => place['name'] == value)) {
                                  _placeErrorText =
                                      'Place not found. If you don’t find the place, ';
                                  selectedPlaceName = null;
                                  selectedPlaceId = null;
                                } else {
                                  _placeErrorText = null; // Clear error
                                  selectedPlaceName = value;
                                  selectedPlaceId = places
                                      .firstWhere((place) =>
                                          place['name'] == value)['id'];
                                }
                              });
                            },
                          );
                        },
                      ),
                      if (_placeErrorText != null)
                        linktoaddpage(), // Call the link widget when needed
                    ],
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _validatePlaceSelection();
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlacePage(),
            ),
          );
        },
        child: Text(
          'go to Add Place Page.',
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