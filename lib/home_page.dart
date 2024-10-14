import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'search_page.dart'; // Import the search page
import 'create_post_page.dart'; // Import the create post page
import 'activity_page.dart'; // Import the activity page

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    Center(child: Text('Welcome to the Home Page!')), // Replace with actual home content
    SearchPage(), // Search Page
    CreatePostPage(), // Create Post Page
    ActivityPage(), // Activity Page
    EditProfileScreen(), // Profile Page
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

  void _onCreatePost() {
    // Action for creating a post
    print('Create a post button pressed');
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
      body: _pages[_selectedIndex],
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
        onTap: _onCreatePost, // Make the plus sign tappable
        child: FloatingActionButton(
          onPressed: null, // Use the plus icon for the post action
          elevation: 4.0, // Disable the default onPressed
          child: Icon(Icons.add), // Floating effect
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, // Centers the button above the nav bar
    );
  }
}