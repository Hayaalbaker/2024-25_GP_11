import 'package:flutter/material.dart';
import 'HomePage.dart';

class InterestsScreen extends StatefulWidget {
  @override
  _InterestsScreenState createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  List<String> interests = ['Restaurants', 'Parks', 'Shopping', 'Children'];

  Map<String, bool> selectedInterests = {
    'Restaurants': false,
    'Parks': false,
    'Shopping': false,
    'Children': false,
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

  Map<String, List<String>> selectedSubInterests = {
    'Restaurants': [],
    'Parks': [],
    'Shopping': [],
    'Children': [],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Interests'),
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
              onPressed: () {
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

  List<Widget> getSubInterests(String interest) {
    List<String> types;
    switch (interest) {
      case 'Restaurants':
        types = restaurantTypes;
        break;
      case 'Parks':
        types = parkTypes;
        break;
      case 'Shopping':
        types = shoppingTypes;
        break;
      case 'Children':
        types = childrenTypes;
        break;
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
