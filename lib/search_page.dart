import 'package:flutter/material.dart';
import 'UserSearchPage.dart';

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
               
                // Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPlacePage()));
              },
              child: Text('Search for Places'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserSearchPage()),
                );
              },
              child: Text('Search for Users'),
            ),
          ],
        ),
      ),
    );
  }
}
