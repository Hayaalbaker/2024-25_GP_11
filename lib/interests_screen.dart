import 'package:flutter/material.dart';
import 'database.dart';
import 'home_page.dart';

class InterestsScreen extends StatefulWidget {
  final String email;
  final String userName;
  final String country;
  final String city;
  final bool isLocalGuide;

  InterestsScreen({
    required this.email,
    required this.userName,
    required this.country,
    required this.city,
    required this.isLocalGuide,
  });

  @override
  _InterestsScreenState createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  List<String> interests = ['Restaurants', 'Parks', 'Shopping', 'Children'];

  Map<String, List<String>> selectedSubInterests = {
    'Restaurants': [],
    'Parks': [],
    'Shopping': [],
    'Children': [],
  };

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

  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Select Your Interests'),
            SizedBox(width: 8),
            Tooltip(
              message:
                  'Your interests will help us offer personalized recommendations for the best Riyadh destinations that match your preferences. Please choose your interests to uncover new hidden gems!',
              preferBelow: false,
              child: Icon(
                Icons.info_outline,
                size: 24,
                color: const Color.fromARGB(255, 213, 9, 9),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: interests.map((interest) {
                return ExpansionTile(
                  title: Row(
                    children: [
                      Icon(getInterestIcon(interest), color: Colors.red),
                      SizedBox(width: 8),
                      Text(interest),
                    ],
                  ),
                  children: getSubInterests(interest),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                List<String> finalInterests = [];
                selectedSubInterests.forEach((interest, subInterests) {
                  if (subInterests.isNotEmpty) {
                    finalInterests.addAll(subInterests);
                  }
                });

                // Ensure that there are interests selected
                if (finalInterests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please select at least one interest!')),
                  );
                  return;
                }

                // Save user details including interests
                await saveUserDetails(finalInterests);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Your interests have been saved successfully!')),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveUserDetails(List<String> finalInterests) async {
    // Call the Firestore service to save user details
    await firestoreService.addUserDetails(
      widget.userName,
      widget.country,
      widget.city,
      finalInterests,
      widget.isLocalGuide,
    );
  }

  List<Widget> getSubInterests(String interest) {
    List<String> types;
    switch (interest) {
      case 'Restaurants':
        types = restaurantTypes;
      case 'Parks':
        types = parkTypes;
      case 'Shopping':
        types = shoppingTypes;
      case 'Children':
        types = childrenTypes;
      default:
        types = [];
    }

    return types.map((type) {
      return CheckboxListTile(
        title: Text(type),
        value: selectedSubInterests[interest]?.contains(type) ?? false,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedSubInterests[interest]?.add(type);
            } else {
              selectedSubInterests[interest]?.remove(type);
            }
          });
        },
      );
    }).toList();
  }

  IconData getInterestIcon(String interest) {
    switch (interest) {
      case 'Restaurants':
        return Icons.restaurant;
      case 'Parks':
        return Icons.park;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Children':
        return Icons.child_care;
      default:
        return Icons.error;
    }
  }
}
