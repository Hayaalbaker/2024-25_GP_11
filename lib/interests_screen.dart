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
  List<String> interests = ['Restaurants', 'Parks', 'Shopping', 'Edutainment'];

  Map<String, List<String>> selectedSubInterests = {
    'Restaurants': [],
    'Parks': [],
    'Shopping': [],
    'Edutainment': [],
  };

List<String> restaurantTypes = [
    "Hong Restaurant",
    "Indian Restaurant",
    "Seafood Restaurant",
    "Italian Restaurant",
    "Lebanese Restaurant",
    "Pizza Restaurant",
    "Korean Restaurant",
    "Sushi Restaurant",
    "Hamburger Restaurant",
    "French Restaurant",
    "Grill Restaurant",
  ];

  List<String> parkTypes = [
    'Family parks',
    'Water parks',
    'Public parks',
  ];

  List<String> shoppingTypes = [
    'Clothing store ',
    'Shoes store',
    'Furniture store',
    'Electronics store',
    'Cosmetics store',
    'Pet store',
    'Jewellery store',
  ];

  List<String> edutainmentTypes = [
    'artial art club',
    'Horse academy',
    'Swimming academy',
    'Pottery classes',
    'Football academy',
    'Yoga studio'
    'Art studio',
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
                color: const Color(0xFF800020),
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
                      Icon(getInterestIcon(interest), color: const Color(0xFF800020)),
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

                if (finalInterests.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please select at least one interest!'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
                  );
                  return;
                }

                await saveUserDetails(finalInterests);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Your interests have been saved successfully!'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
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
        types = edutainmentTypes;
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
