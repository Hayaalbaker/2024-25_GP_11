import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database.dart';
import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_popup/info_popup.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:developer';

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
  XFile? imageFile;
  final ImagePicker _picker = ImagePicker();

  TextEditingController _placeNameController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  final List<String> mainCategories = [
    'Restaurants',
    'Parks',
    'Shopping',
    'Children',
  ];

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

  final Map<String, String> categoryImages = {
    'restaurants': 'images/Restaurant.png',
    'parks': 'images/Park.png',
    'shopping': 'images/Shopping.png',
    'children': 'images/children.png',
  };

  String? selectedMainCategory;
  List<String>? availableSubCategories;
  String? selectedSubCategory;
  String? selectedImagePath;

  bool check_values = false;
  final FirestoreService _firestoreService =
      FirestoreService(); 

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
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 50, left: 20, right: 20),
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> doesPlaceExist() async {
    String lowerCasePlaceName =
        placeName.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    String lowerCaseCategory =
        category.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    QuerySnapshot allPlaces =
        await FirebaseFirestore.instance.collection('places').get();

    try {

      List<QueryDocumentSnapshot> matchingPlaces = allPlaces.docs.where((doc) {
        String dbPlaceName = doc['place_name']
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        String dbCategory = doc['category']
            .toString()
            .replaceAll(RegExp(r'\s+'), '')
            .toLowerCase();
        return dbPlaceName == lowerCasePlaceName &&
            dbCategory == lowerCaseCategory;
      }).toList();
      return matchingPlaces.isNotEmpty;
    } catch (e) {
      print("Error querying Firestore: $e");
      return false;
    }
  }

  Future<void> _submitPlace() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        bool exists = await doesPlaceExist();
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Cannot add the place because it already exists. Please add another one.'),
          ));
          return;
        }

        DocumentReference newPlaceRef =
            FirebaseFirestore.instance.collection('places').doc();

        String imageUrl;

        if (imageFile != null) {
          final storageRef = FirebaseStorage.instance.ref();
          final imageRef = storageRef
              .child('places/${DateTime.now().toIso8601String()}.jpg');

          await imageRef.putFile(File(imageFile!.path));
          imageUrl = await imageRef.getDownloadURL();
        } else {
          imageUrl = categoryImages[category.toLowerCase()] ??
              'images/place_default_image.png'; 
        }

        await newPlaceRef.set({
          'placeId': newPlaceRef.id,
          'place_name': placeName,
          'description': description,
          'location': location,
          'category': category,
          'subcategory': subcategory,
          'created_at': FieldValue.serverTimestamp(),
          'Neighborhood': Neighborhood,
          'Street': Street,
          'user_uid': userID,
          'imageUrl': imageUrl, 
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Place Added: $placeName Successfully!'),
        ));

        _formKey.currentState!.reset();
        setState(() {
          imageFile = null;
          category = '';
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add place: $e'),
        ));
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      imageFile = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a Place"),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('More Info'),
                        SizedBox(width: 10),
                        Icon(Icons.info),
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
                        subCategories[value]; 
                    selectedSubCategory = null; 
                    selectedImagePath =
                        categoryImages[value]; 
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
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text('Upload Image'),
              ),
              if (imageFile != null)
                Image.file(
                  File(imageFile!.path),
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitPlace,
                child: Text('Add Place'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}