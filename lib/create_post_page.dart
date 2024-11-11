import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


/*class CreatePostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Create Post Page'));
  }
}*/

void main() {
  runApp(CreatePostPage());
}

class CreatePostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post a Review',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReviewForm(),
    );
  }
}

class ReviewForm extends StatefulWidget {
  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  String ReviewText = '';
  String PostDate = '';
  List<String>? LikeCount;
  int Rating = 1;
  String placeId = '';
  String user_uid = '';
  final TextEditingController _reviewController = TextEditingController();

  bool isLoading = false;

  List<Map<String, String>> places = [];
  String? selectedPlaceName;
  String? selectedPlaceId;

  final FirestoreService _firestoreService =
      FirestoreService(); // Create an instance of FirestoreService

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchPlaces();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        user_uid = user.uid;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load user data: $e'),
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });
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
        selectedPlaceName = places.isNotEmpty ? null : selectedPlaceName;
      });
    } catch (e) {
      print('Error fetching places: $e');
    }
  }

  Future<void> saveReview() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Reference to the 'reviews' collection in Firestore
        DocumentReference newReviewRef =
            FirebaseFirestore.instance.collection('Review').doc();

        // Save the review details to Firestore
        await newReviewRef.set({
          'Review_Text': ReviewText,
          'user_uid': user_uid,
          'placeId': selectedPlaceId, // ID of the selected place from dropdown
          'Rating': Rating,
          'Post_Date': FieldValue.serverTimestamp(),
          'Like_count': LikeCount,
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Review posted successfully!'),
        ));

        // Navigate to HomePage or another relevant page after saving the review
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

/*
    Future<void> storeSelectedPlace(String placeId) async {
    try {
      await FirebaseFirestore.instance.collection('userSelections').add({
        'selectedPlaceId': placeId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Selected place ID stored successfully!');
    } catch (e) {
      print('Error storing selected place ID: $e');
    }
  }
*/
/*

// Update user profile in Firestore
  Future<void> checkPlace() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
      //  User? user = _auth.currentUser;
          DocumentReference newPlaceRef = FirebaseFirestore.instance.collection('places').doc();
        // Convert input to lowercase for case-insensitive checking
        String lowerCasePlaceName = placeName.trim().toLowerCase();
        String lowerCaseCategory = category.trim().toLowerCase();

        // Check if email or username already exists
        QuerySnapshot placeNameCheck = await FirebaseFirestore.instance
            .collection('places')
            .where('place_name', isEqualTo: lowerCasePlaceName)
            .get();
        QuerySnapshot categoryCheck = await FirebaseFirestore.instance
            .collection('places')
            .where('category', isEqualTo: lowerCaseCategory)
            .get();

        // Check if the email already exists and does not belong to the current user
        if (placeNameCheck.docs.isNotEmpty &&
            categoryCheck.docs.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('cant add the place becouse it is already exists. please add other one ')));
          return;
        }else{

                    newPlaceRef.set({
                      'placeId': newPlaceRef.id, // Save the generated place ID
                      'place_name': placeName,
                      'description': description,
                      'location': location,
                      'category': category,
                      'subcategory': subcategory, // Save selected subcategory
                      'created_at': FieldValue.serverTimestamp(),
                      'Neighborhood': Neighborhood,
                      'Street': Street,
                      'user_uid': userID,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Place Added: $placeName Successfully!'),
                    )
                    
                    );
                                        Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              HomePage()), // Ensure this points to your AddPlacePage
                    );

        }


      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }*/

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
              style: TextStyle(color: const Color.fromARGB(255, 16, 0, 0)),
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
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() {
                    Rating = rating.toInt(); // Store the rating as an int
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
                child: Text(place['name']!), // Correct placement of child
              );
            }).toList(),
          ), 
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ReviewText = _reviewController
                      .text; // Set ReviewText from the TextField
                  saveReview(); // Call the saveReview method
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
