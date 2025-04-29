import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localize/Notifications_page.dart';
import 'package:localize/message_screen.dart';
import 'search_page.dart'; 
import 'create_post_page.dart'; 
import 'add_place.dart'; 
import 'welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'places_widget.dart';
import 'profile_screen.dart'; 
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
      debugShowCheckedModeBanner: false, 
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
  int _selectedIndex = 0; 
  static const Color _iconColor = Color(0xFF800020); 
  late TabController _tabController; 

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); 
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; 
    });
  }

  void _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    } catch (e) {
      print("Error signing out: $e"); 
    }
  }

  void _onCreatePost() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 220, 
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
                    color: const Color(0xFF800020)),
                title: Text('Post a Review'),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePostPage(ISselectplace: false)),
                  ); 
                },
              ),
              ListTile(
                leading: Icon(Icons.add_location_alt, color: _iconColor),
                title: Text('Add a Place'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddPlacePage()));
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                            .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox();

                          int unreadUsersCount = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>?;
                            final unreadCount = data?['unreadCount'] as Map<String, dynamic>?;
                            return unreadCount != null &&
                                unreadCount[FirebaseAuth.instance.currentUser!.uid] != null &&
                                unreadCount[FirebaseAuth.instance.currentUser!.uid] > 0;
                          }).length;

                          return unreadUsersCount > 0
                              ? Positioned(
                                  right: -2,
                                  top: -6,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text('$unreadUsersCount', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  ),
                                )
                              : SizedBox();
                        },
                      ),
                    ],
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => MessageListScreen(currentUserId: FirebaseAuth.instance.currentUser!.uid),
                  )),
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
                labelColor: _iconColor,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.rate_review), text: "Reviews"),
                  Tab(icon: Icon(Icons.place), text: "Places"),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            Review_widget(),
            Container(padding: EdgeInsets.zero, child: viewPlaces()),
          ],
        ),
      ),
      SearchPage(),
      CreatePostPage(ISselectplace: false),
      ActivityPage(),
      ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
    ];

    return Scaffold(
      body: _pages[
          _selectedIndex], 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
      floatingActionButton: FloatingActionButton(
        elevation: 4.0,
        onPressed: _onCreatePost,
        backgroundColor: _iconColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget viewPlaces() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: _iconColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.place, size: 20), child: Text("All", style: TextStyle(fontSize: 12))),
              Tab(icon: Icon(Icons.restaurant, size: 20), child: Text("Restaurants", style: TextStyle(fontSize: 12))),
              Tab(icon: Icon(Icons.park, size: 20), child: Text("Parks", style: TextStyle(fontSize: 12))),
              Tab(icon: Icon(Icons.shopping_bag, size: 20), child: Text("Shopping", style: TextStyle(fontSize: 12))),
              Tab(icon: Icon(Icons.child_care, size: 20), child: Text("Edutainment", style: TextStyle(fontSize: 12))),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                PlacesWidget(filterCategory: "All Categories"),
                PlacesWidget(filterCategory: "Restaurants"),
                PlacesWidget(filterCategory: "Parks"),
                PlacesWidget(filterCategory: "Shopping"),
                PlacesWidget(filterCategory: "Edutainment"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

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
