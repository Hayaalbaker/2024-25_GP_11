import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_popup/info_popup.dart';

void main() {
  runApp(AddPlacePage());
}

class AddPlacePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Add a Place',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlaceForm(),
    );
  }
}

class PlaceForm extends StatefulWidget {
  @override
  _PlaceFormState createState() => _PlaceFormState();
}

class _PlaceFormState extends State<PlaceForm> {
  final _formKey = GlobalKey<FormState>();
  String placeName = '';
  String location = '';
  String description = '';
  String category = '';
  String Neighborhood = '';
  String Street = '';
  String? subcategory;
  bool isLoading = false;
  String userID = '';
// Main categories for the first dropdown
  final List<String> mainCategories = [
    'Restaurants',
    'Parks',
    'Shopping',
    'Children',
  ];

  // Subcategories map
  final Map<String, List<String>> subCategories = {
    'Restaurants': [
      'Seafood Restaurants',
      'Vegan Restaurants',
      'Indian Restaurants',
      'Italian Restaurants',
      'Lebanese Restaurants',
      'Traditional Saudi Restaurants',
      'Fast Food',
    ],
    'Parks': [
      'Family Parks',
      'Water Parks',
      'Public Parks',
    ],
    'Shopping': [
      'Traditional Markets',
      'Modern Markets',
      'Food Markets',
      'Clothing Markets',
      'Perfume Markets',
      'Jewelry Markets',
      'Electronics Markets',
      'Pet Markets',
      'Gift and Souvenir Markets',
      'Home Goods Markets',
    ],
    'Children': [
      'Recreational Centers',
      'Sports Facilities',
      'Educational Workshops',
    ],
  };

  String? selectedMainCategory;
  List<String>? availableSubCategories;
  String? selectedSubCategory;

  bool check_values = false;
  final FirestoreService _firestoreService =
      FirestoreService(); // Create an instance of FirestoreService

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        userID = user.uid;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Place'),
      ),

/*appBar: AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HomePage()),
  );
}
  ), 
  title: Text("Add a Place"),
  centerTitle: true,
),
*/

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Place Name*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a place name';
                  }
                  return null;
                },
                onSaved: (value) {
                  placeName = value!;
                },
              ),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    decoration:
                        InputDecoration(hintText: "Neighborhood/Locality"),
                    onSaved: (value) {
                      Neighborhood = value!;
                    },
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(hintText: "Street Address"),
                    onSaved: (value) {
                      Street = value!;
                    },
                  ),
                )
              ]),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location*',
                  suffixIcon: InfoPopupWidget(
                    contentTitle: ' (Provide Google Maps Link)',
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Wrap content tightly
                      children: [
                        Text('More Info'), // The text goes first
                        SizedBox(
                            width: 10), // Add spacing between text and icon
                        Icon(Icons.info), // The icon goes after the text
                      ],
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  String pattern =
                      r"^(https:\/\/www\.google\.com\/maps\/(place|dir)\/|https:\/\/maps\.app\.goo\.gl\/|https:\/\/goo\.gl\/maps\/).+";
                  RegExp regex = RegExp(pattern);
                  if (!regex.hasMatch(value)) {
                    return 'Please enter a valid Google Maps link';
                  }
                  return null;
                },
                onSaved: (value) {
                  location = value!;
                },
              ),

              TextFormField(
                decoration: InputDecoration(labelText: 'Description*'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  description = value!;
                },
              ),
              // First Dropdown (Main Category)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category*'),
                value: selectedMainCategory,
                items: mainCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMainCategory = value!;
                    availableSubCategories =
                        subCategories[value]; // Update available subcategories
                    selectedSubCategory =
                        null; // Reset subcategory when main category changes
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                onSaved: (value) {
                  category = value!;
                },
              ),

              // Second Dropdown (Sub Category), shown only when a main category is selected
              if (availableSubCategories != null)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Subcategory'),
                  value: selectedSubCategory,
                  items: availableSubCategories!.map((String subCategory) {
                    return DropdownMenuItem<String>(
                      value: subCategory,
                      child: Text(subCategory),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubCategory = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a subcategory';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    subcategory = value!;
                  },
                ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  //check_values= await checkAndDisplayResult( placeName,  category);

                  checkAndDisplayResult(placeName, category);
                  if (check_values) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'cant add the place becouse the Place name: $placeName, and the category: $category is already added'),
                    ));
                  } else {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      DocumentReference newPlaceRef =
                          FirebaseFirestore.instance.collection('places').doc();

                      newPlaceRef.set({
                        'placeId':
                            newPlaceRef.id, // Save the generated place ID
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
                        content:
                            Text('Place Added: $placeName, user id: $userID'),
                      ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                HomePage()), // Ensure this points to your AddPlacePage
                      );
                    }
                  }
                },
                child: Text('Add Place'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> isNameExists(String name) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('places') // replace with your collection name
        .where('Place_Name', isEqualTo: name)
        .get();

    // Check if any documents exist with the matching name
    return querySnapshot.docs.isNotEmpty;
  }

  Future<bool> isCategoryExists(String category) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('places') // replace with your collection name
        .where('Category', isEqualTo: category)
        .get();

    // Check if any documents exist with the matching name
    return querySnapshot.docs.isNotEmpty;
  }

  void checkAndDisplayResult(String name, String category) async {
    bool nameExists = await isNameExists(name);
    bool nameExists2 = await isCategoryExists(category);

    if (nameExists && nameExists2) {
      check_values = true;
    } else {
      check_values = false;
    }
  }
}
