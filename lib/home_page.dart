import 'package:flutter/material.dart';
import 'search_page.dart'; // Import the search page
import 'create_post_page.dart'; // Import the create post page
import 'activity_page.dart'; // Import the activity page
import 'add_place.dart'; // Import the Add Place page
import 'welcome_screen.dart'; // Import the welcome screen
import 'package:firebase_auth/firebase_auth.dart';
import 'places_widget.dart'; // Import the Places widget
import 'profile_screen.dart'; // Import the profile screen
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Index to track the selected page
  static const Color _iconColor =
      Color.fromARGB(255, 218, 0, 0); // Constant color for icons

  // List of pages to show in the app
  static List<Widget> _pages = <Widget>[
    Center(child: Places_widget()), // Home page
    SearchPage(), // Search Page
    CreatePostPage(), // Create Post Page
    ActivityPage(), // Activity Page
    ProfileScreen(), // Profile Page
  ];



  // Titles for each page displayed in the AppBar
  List<String> _titles = [
    'Home',
    'Search',
    'Create Post',
    'Notifications',
    'Profile',
  ];

  // Method to change the selected page
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Method to handle sign-out process
  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out from Firebase
      print("User signed out");

      // Navigate to the welcome screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    } catch (e) {
      print("Error signing out: $e"); // Print any errors
    }
  }

  // Method to show modal bottom sheet for creating posts or adding places
  void _onCreatePost() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 220, // Height of modal bottom sheet
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an action',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.rate_review,
                    color: const Color.fromARGB(255, 218, 0, 0)), // Set color
                title: Text('Post a Review'),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePostPage()),
                  ); // Navigate to Create Post Page
                },
              ),
              ListTile(
                leading: Icon(Icons.add_location_alt,
                    color: const Color.fromARGB(236, 218, 0, 0)), // Set color
                title: Text('Add a Place'),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPlacePage()),
                  ); // Navigate to Add Place Page
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_titles[_selectedIndex]), // Set title based on selected page
        automaticallyImplyLeading: false, // Remove default back button
        actions: [
          if (_selectedIndex == 0) // Show direct message icon on Home page only
            IconButton(
              icon: Icon(Icons.chat_bubble_outline,
                  color: _iconColor), // Set color
              onPressed: () {
                // Action for direct messages
              },
            ),
          IconButton(
            icon: Icon(Icons.logout,
                color: _iconColor), // Set color for sign-out icon
            onPressed: _signOut, // Call the sign-out method
            tooltip: 'Sign Out', // Tooltip for accessibility
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page content
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
            left: 10, right: 10, bottom: 10), // Margin for a floating effect
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10, // Shadow for floating effect
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0, // Remove default shadow
          currentIndex: _selectedIndex, // Highlight the selected icon
          onTap: _onItemTapped, // Change selected page on tap
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.home,
                    color: const Color.fromARGB(255, 184, 57, 57)),
                label: ''), // Home
            BottomNavigationBarItem(
                icon: Icon(Icons.search,
                    color: const Color.fromARGB(255, 184, 57, 57)),
                label: ''), // Search
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box,
                  color: const Color.fromARGB(
                      255, 184, 57, 57)), // Create post icon
              label: 'Post',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.notifications,
                    color: const Color.fromARGB(255, 184, 57, 57)),
                label: ''), // Activity
            BottomNavigationBarItem(
                icon: Icon(Icons.person,
                    color: const Color.fromARGB(255, 184, 57, 57)),
                label: ''), // Profile
          ],
          selectedItemColor: const Color.fromARGB(
              255, 184, 57, 57), // Set color for selected icon
          unselectedItemColor: const Color.fromARGB(
              255, 184, 57, 57), // Set color for unselected icons
          type: BottomNavigationBarType.fixed,
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _onCreatePost, // Show modal on tapping the floating button
        child: FloatingActionButton(
          elevation: 4.0,
          onPressed: _onCreatePost, // Show modal bottom sheet on press
          backgroundColor: _iconColor, // Set color for the floating button
          child: Icon(Icons.add,
              color: Colors.white), // Floating plus icon with white color
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerDocked, // Center the button above the nav bar
    );
  }
}
