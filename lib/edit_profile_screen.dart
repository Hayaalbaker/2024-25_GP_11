import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Controllers
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _nameController = TextEditingController();

  String? _imageUrl;
  File? _pickedImage;

  // For dropdown lists
  String? _selectedCity;
  String? _selectedCountry;

  List<String> countries = [
    'Saudi Arabia',
    'Egypt',
    'United Arab Emirates',
    'Kuwait',
  ];

  Map<String, List<String>> cities = {
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
  };

  // Selected interests and sub-interests
  Map<String, List<String>> selectedSubInterests = {
    'Restaurants': [],
    'Parks': [],
    'Shopping': [],
    'Children': [],
  };

  List<String> selectedInterests = [];

  List<String> restaurantTypes = [
    'Seafood restaurants',
    'Vegan restaurants',
    'Indian restaurants',
    'Italian restaurants',
    'Lebanese Restaurants',
    'Traditional Saudi restaurants',
    'Fast food'
  ];

  List<String> parkTypes = [
    'Family parks',
    'Water parks',
    'Public parks',
  ];

  List<String> shoppingTypes = [
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
  ];

  List<String> childrenTypes = [
    'Recreational Centers',
    'Sports Facilities',
    'Educational Workshops',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _emailController.text = user.email!;

        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>;

          _usernameController.text = data['user_name'] ?? '';
          _nameController.text = data['Name'] ?? '';
          _selectedCity = data['city'] ?? null;
          _selectedCountry = data['country'] ?? null;
          _imageUrl = data['profileImageUrl'] ?? null;

          // Load existing interests
          selectedInterests = List<String>.from(data['interests'] ?? []);

          // Populate the selectedSubInterests based on existing interests
          for (var interest in selectedInterests) {
            if (restaurantTypes.contains(interest)) {
              selectedSubInterests['Restaurants']!.add(interest);
            } else if (parkTypes.contains(interest)) {
              selectedSubInterests['Parks']!.add(interest);
            } else if (shoppingTypes.contains(interest)) {
              selectedSubInterests['Shopping']!.add(interest);
            } else if (childrenTypes.contains(interest)) {
              selectedSubInterests['Children']!.add(interest);
            }
          }
        }
      });
    }
  }

  // Pick an image
  Future<void> _pickImage() async {
    final pickedImageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });
    }
  }

// Update user profile in Firestore
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = _auth.currentUser;

        // Convert input to lowercase for case-insensitive checking
        String lowerCaseEmail = _emailController.text.trim().toLowerCase();
        String lowerCaseUsername = _usernameController.text.trim().toLowerCase();

        // Check if email or username already exists
        QuerySnapshot emailCheck = await _firestore
            .collection('users')
            .where('email', isEqualTo: lowerCaseEmail)
            .get();
        QuerySnapshot usernameCheck = await _firestore
            .collection('users')
            .where('user_name', isEqualTo: lowerCaseUsername)
            .get();

        // Check if the email already exists and does not belong to the current user
        if (emailCheck.docs.isNotEmpty &&
            emailCheck.docs.first.id != user?.uid) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Email already exists.')));
          return;
        }

        // Check if the username already exists and does not belong to the current user
        if (usernameCheck.docs.isNotEmpty &&
            usernameCheck.docs.first.id != user?.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Username already exists.')));
          return;
        }

        // Update user email if necessary
        if (user != null && user.email != lowerCaseEmail) {
          await user.updateEmail(lowerCaseEmail);
        }

        // Upload new profile picture if selected
        String? profileImageUrl;
        if (_pickedImage != null) {
          final storageRef =
          _storage.ref().child('profileImages/${user!.uid}.jpg');
          await storageRef.putFile(_pickedImage!);
          profileImageUrl = await storageRef.getDownloadURL();
        } else {
          profileImageUrl = _imageUrl;
        }

        // Prepare the selected interests (only the ones that are currently checked)
        List<String> newInterests = [];
        selectedSubInterests.forEach((category, interests) {
          newInterests.addAll(interests);
        });

        // Load the current interests from Firestore to check if there is a change
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user!.uid).get();
        List<String> currentInterests =
        List<String>.from(userDoc['interests'] ?? []);

        // Update Firestore only if interests have changed
        if (newInterests
            .toSet()
            .difference(currentInterests.toSet())
            .isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update({
            'interests': newInterests, // Only update if there's a change
          });
        }

        // Update other fields without affecting interests unnecessarily
        await _firestore.collection('users').doc(user.uid).update({
          'user_name': lowerCaseUsername, // Store in lowercase
          'Name': _nameController.text.trim(), // Trimmed Name
          'city': _selectedCity,
          'country': _selectedCountry,
          'email': lowerCaseEmail, // Store in lowercase
          'profileImageUrl': profileImageUrl,
        });

        _loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')));
      }
    }
  }


  // Subinterest selection widget
  Widget _buildSubInterestSelection(String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 10.0,
          children: options.map((option) {
            bool isSelected = selectedSubInterests[category]!.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    // Add to the list of selected sub-interests
                    selectedSubInterests[category]!.add(option);
                  } else {
                    // Remove from the list of selected sub-interests
                    selectedSubInterests[category]!.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (_imageUrl != null
                          ? NetworkImage(_imageUrl!) as ImageProvider
                          : null),
                  child: _pickedImage == null && _imageUrl == null
                      ? Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid name.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid username.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(labelText: 'Country'),
                items: countries.map((country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                    _selectedCity = null; // Reset the city when country changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a country.';
                  }
                  return null;
                },
              ),
              if (_selectedCountry != null)
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(labelText: 'City'),
                  items: cities[_selectedCountry]!.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a city.';
                    }
                    return null;
                  },
                ),
              SizedBox(height: 20),
              _buildSubInterestSelection('Restaurants', restaurantTypes),
              _buildSubInterestSelection('Parks', parkTypes),
              _buildSubInterestSelection('Shopping', shoppingTypes),
              _buildSubInterestSelection('Children', childrenTypes),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
