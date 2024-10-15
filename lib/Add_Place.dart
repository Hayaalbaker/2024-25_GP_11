import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'database.dart';

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
  String? subcategory;
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

  final FirestoreService _firestoreService = FirestoreService(); // Create an instance of FirestoreService
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Place'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Place Name'),
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
              TextFormField(
  decoration: const InputDecoration(labelText: 'Location (Provide Google Maps Link)'),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a location';
    }
    String pattern = r"^(https:\/\/www\.google\.com\/maps\/(place|dir)\/|https:\/\/maps\.app\.goo\.gl\/|https:\/\/goo\.gl\/maps\/).+";
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
                decoration: InputDecoration(labelText: 'Description'),
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
                decoration: InputDecoration(labelText: 'Category'),
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
                    availableSubCategories = subCategories[value]; // Update available subcategories
                    selectedSubCategory = null; // Reset subcategory when main category changes
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
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    
                    
                    DocumentReference newPlaceRef = FirebaseFirestore.instance.collection('places').doc();

                    
                    newPlaceRef.set({
                      'placeId': newPlaceRef.id, // Save the generated place ID
                      'place_name': placeName,
                      'description': description,
                      'location': location,
                      'category': category,
                      'subcategory': subcategory, // Save selected subcategory
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Place Added: $placeName, ID: ${newPlaceRef.id}'),
                    ));
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
}
