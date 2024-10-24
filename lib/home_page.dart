import 'package:flutter/material.dart';
import 'search_page.dart'; // Import the search page
import 'create_post_page.dart'; // Import the create post page
import 'activity_page.dart'; // Import the activity page
import 'add_place.dart'; // Import your Add Place page here
import 'welcome_screen.dart'; // Import your welcome screen here
import 'package:firebase_auth/firebase_auth.dart';
import 'places_widget.dart'; 
import 'profile_screen.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    Center(child: Places_widget()), // Replace with actual home content ???
    SearchPage(), // Search Page
    CreatePostPage(), // Create Post Page
    ActivityPage(), // Activity Page
    ProfileScreen(), // Profile Page
  ];

  // Titles for each page
  List<String> _titles = [
    'Home',
    'Search',
    'Create Post',
    'Activity',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
// Method to handle sign out
void _signOut() async {
  try {
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
    print("User signed out");
    
    // Navigate to the welcome screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => WelcomeScreen()), // Navigate to WelcomeScreen
    );
  } catch (e) {
    print("Error signing out: $e"); // Print any errors to the console
  }
}

  // Inside your _onCreatePost function:
  void _onCreatePost() {
    // Show a modal bottom sheet with options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 220, // Set height for modal
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an action',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.rate_review),
                title: Text('Post a Review'),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  // Navigate to Create Post Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePostPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add_location_alt),
                title: Text('Add a Place'),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  // Navigate to Add Place Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPlacePage()), // Ensure this points to your AddPlacePage
                  );
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
        title: Text(_titles[_selectedIndex]), // Set title based on selected index
        actions: [
          if (_selectedIndex == 0) // Show direct message icon only on Home page
            IconButton(
              icon: Icon(Icons.chat_bubble_outline), // Chat bubble icon for direct messages
              onPressed: () {
                // Add action for direct messages
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]), // Use Expanded to take full height for the pages
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _signOut, // Text for the button
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Use backgroundColor instead of primary
                padding: EdgeInsets.symmetric(vertical: 16.0), // Padding
                textStyle: TextStyle(fontSize: 18), // Text style
              ), // Call sign-out method
              child: Text('Sign Out'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(left: 10, right: 10, bottom: 10), // Margin for the floating effect
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
          backgroundColor: Colors.transparent, // Make the background transparent
          elevation: 0, // Remove default shadow
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box), // Post icon
              label: 'Post',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Activity'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedItemColor: Colors.black, // Color of selected icon
          unselectedItemColor: Colors.grey, // Color of unselected icons
          type: BottomNavigationBarType.fixed,
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _onCreatePost, // Show the modal when the plus button is tapped
        child: FloatingActionButton(
          elevation: 4.0,
          onPressed: _onCreatePost,
          child: Icon(Icons.add), // Floating plus icon
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the nav bar
    );
  }
}