import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_page.dart';
import 'profile_settings.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  TextEditingController _nameController = TextEditingController();

  String? _imageUrl;
  File? _pickedImage;

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

  bool _hasChanges = false; 

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _nameController.text = userDoc['Name'] ?? '';
        _imageUrl = userDoc['profileImageUrl'];

        selectedInterests = List<String>.from(userDoc['interests'] ?? []);

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
      });
    }
  }

  void _trackChanges() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _pickImage() async {
    final pickedImageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
        _trackChanges();
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Discard Changes?'),
              content: Text('You have unsaved changes. Do you want to discard them?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Discard'),
                ),
              ],
            ),
          )) ??
          false;
    }
    return true;
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = _auth.currentUser;

        String? profileImageUrl;
        if (_pickedImage != null) {
          final storageRef =
              _storage.ref().child('profileImages/${user!.uid}.jpg');
          await storageRef.putFile(_pickedImage!);
          profileImageUrl = await storageRef.getDownloadURL();
        } else {
          profileImageUrl = _imageUrl;
        }

        List<String> newInterests = [];
        selectedSubInterests.forEach((category, interests) {
          newInterests.addAll(interests);
        });

        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        List<String> currentInterests =
            List<String>.from(userDoc['interests'] ?? []);

        if (newInterests.toSet().difference(currentInterests.toSet()).isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update({
            'interests': newInterests,
          });
        }

        await _firestore.collection('users').doc(user.uid).update({
          'Name': _nameController.text.trim(),
          'profileImageUrl': profileImageUrl,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $e'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
        ));
      }
    }
  }

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
                    selectedSubInterests[category]!.add(option);
                  } else {
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
    return WillPopScope(
      onWillPop: _onWillPop, 
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileSettingsPage()),
                );
              },
            ),
          ],
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
      ),
    );
  }
}