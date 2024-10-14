import 'package:flutter/material.dart';
import 'edit_profile_screen.dart'; // تأكد من استيراد صفحة التعديل

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // قائمة الصفحات
  static List<Widget> _pages = <Widget>[
    Center(child: Text('Welcome to the Home Page!')),
    EditProfileScreen(), // صفحة تعديل الملف الشخصي
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: _pages[_selectedIndex], // تحديد الصفحة حسب الفهرس
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
