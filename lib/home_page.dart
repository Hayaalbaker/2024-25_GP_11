import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localize/Notifications_page.dart';
import 'package:localize/message_screen.dart';
import 'search_page.dart'; // Import the search page
import 'create_post_page.dart'; // Import the create post page
// Import the activity page
import 'add_place.dart'; // Import the Add Place page
import 'welcome_screen.dart'; // Import the welcome screen
import 'package:firebase_auth/firebase_auth.dart';
import 'places_widget.dart'; // Import the Places widget
import 'profile_screen.dart'; // Import the profile screen
import 'review_widget.dart';
import 'Message_List_Screen.dart';
import 'package:badges/badges.dart' as badges;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove the debug banner here
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Index to track the selected page
  static const Color _iconColor = Color(0xFF800020); // Constant color for icons
  late TabController _tabController; // TabController for managing tabs

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize TabController
  }

  // Method to change the selected page
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
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
                    color: const Color(0xFF800020)), // Set color
                title: Text('Post a Review'),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePostPage(ISselectplace: false)),
                  ); // Navigate to Create Post Page
                },
              ),
              ListTile(
                leading: Icon(Icons.add_location_alt,
                    color: const Color(0xFF800020)), // Set color
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
  void dispose() {
    _tabController.dispose(); // Dispose of the TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              actions: [
                SizedBox(
                  width: 45,
                  child: IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.message_sharp),
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .where('participants',
                                  arrayContains:
                                      FirebaseAuth.instance.currentUser!.uid)
                              .snapshots(),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return SizedBox();
                            }

                            int unreadUsersCount =
                                snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>?;
                              final unreadCount =
                                  data?['unreadCount'] as Map<String, dynamic>?;

                              return unreadCount != null &&
                                  unreadCount[FirebaseAuth
                                          .instance.currentUser!.uid] !=
                                      null &&
                                  unreadCount[FirebaseAuth
                                          .instance.currentUser!.uid] >
                                      0;
                            }).length;

                            return unreadUsersCount > 0
                                ? Positioned(
                                    right: -2,
                                    top: -6,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$unreadUsersCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox();
                          },
                        ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageListScreen(
                            currentUserId:
                                FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                collapseMode: CollapseMode.parallax,
                background: Image.network(
                  "https://images.pexels.com/photos/1885719/pexels-photo-1885719.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Color(0xFF800020),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.rate_review), text: "Reviews"),
                    Tab(icon: Icon(Icons.place), text: "Places"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            Review_widget(), 
                Container(
      padding: EdgeInsets.zero, // Ensures no padding
      child: viewPlaces(),
    ),
            // Replace with actual reviews content
             // Display the Places widget here
          ],
        ),
      ),
      SearchPage(), // Navigate to Search Page
      CreatePostPage(ISselectplace: false), // Navigate to Create Post Page
      ActivityPage(), // Navigate to Activity Page
      ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
      // Navigate to Profile Page
    ];

    return Scaffold(
      body: _pages[
          _selectedIndex], // Display the selected page based on the index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight the selected icon
        onTap: _onItemTapped, // Change selected page on tap
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color:
                  _selectedIndex == 0 ? const Color(0xFF800020) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search,
              color:
                  _selectedIndex == 1 ? const Color(0xFF800020) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_box,
              color:
                  _selectedIndex == 2 ? const Color(0xFF800020) : Colors.grey,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('receiverUid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                bool hasUnreadNotifications = false;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  hasUnreadNotifications = true;
                }

                return badges.Badge(
                  showBadge: hasUnreadNotifications,
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(5),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: _selectedIndex == 3
                        ? const Color(0xFF800020)
                        : Colors.grey,
                  ),
                );
              },
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color:
                  _selectedIndex == 4 ? const Color(0xFF800020) : Colors.grey,
            ),
            label: '',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 184, 57, 57),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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
 Widget viewPlaces() {
  return DefaultTabController(
    length: 5, // Number of tabs
    child: Column(
      children: [
        TabBar(
          isScrollable: true, // Enable scrolling for the tabs
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: Color(0xFF800020),
          unselectedLabelColor: Colors.grey,
          padding: EdgeInsets.zero, // Remove extra padding
          labelPadding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust tab padding
          tabs: const [
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize the size of the tab
                children: [
                  Icon(Icons.place, size: 20), // Smaller icon size
                  SizedBox(height: 4), // Adjust spacing
                  Text(
                    "All",
                    style: TextStyle(fontSize: 12), // Smaller text size
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant, size: 20),
                  SizedBox(height: 4),
                  Text(
                    "Restaurants",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.park, size: 20),
                  SizedBox(height: 4),
                  Text(
                    "Parks",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag, size: 20),
                  SizedBox(height: 4),
                  Text(
                    "Shopping",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.child_care, size: 20),
                  SizedBox(height: 4),
                  Text(
                    "Children",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              Places_widget(filterCategory: "All Categories"),
              Places_widget(filterCategory: "Restaurants"),
              Places_widget(filterCategory: "Parks"),
              Places_widget(filterCategory: "Shopping"),
              Places_widget(filterCategory: "Children"),
            ],
          ),
        ),
      ],
    ),
  );
}


}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _tabBar;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }

       
  

}
