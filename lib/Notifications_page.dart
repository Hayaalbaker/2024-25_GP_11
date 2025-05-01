import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    Future<void> markNotificationsAsRead() async {
      QuerySnapshot notifications = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('receiverUid', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        await doc.reference.update({'isRead': true});
      }
    }

    markNotificationsAsRead();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('receiverUid', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching notifications'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications yet'));
          }
          
return ListView(
  children: snapshot.data!.docs.map((doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // 💬 Case 1: Like/Review Notification
      if (data.containsKey('reviewId')) {
        String reviewId = data['reviewId'];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('Review').doc(reviewId).get(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return ListTile(title: Text('Loading review...'));
            }
            if (!reviewSnapshot.hasData || reviewSnapshot.hasError) {
              return ListTile(title: Text('Review not found'));
            }

            Map<String, dynamic>? reviewData = reviewSnapshot.data!.data() as Map<String, dynamic>?;
            List<dynamic> likeCount = reviewData?['Like_count'] ?? [];

            if (likeCount.isEmpty) {
              return ListTile(title: Text('No likes yet'), subtitle: Text(reviewData?['Review_Text'] ?? ''));
            }

            String firstUserId = likeCount[0];
            int others = likeCount.length - 1;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(firstUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(title: Text('Loading user...'));
                }

                String firstUserName = userSnapshot.data?.get('user_name') ?? 'Someone';
                String message = others > 0
                    ? '$firstUserName and $others others liked your review'
                    : '$firstUserName liked your review';

                return ListTile(
                  leading: Icon(Icons.favorite),
                  title: Text(message),
                  subtitle: Text(reviewData?['Review_Text'] ?? ''),
                  trailing: Text(
                    (data['timestamp'] as Timestamp).toDate().toString(),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              },
            );
          },
        );
      }

      // 📌 Case 2: Generic notification (admin alerts, etc.)
      if (data.containsKey('message')) {
        String message = data['message'] ?? 'Notification';
        Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

        return ListTile(
          leading: Icon(Icons.notifications),
          title: Text(message),
          trailing: Text(
            timestamp.toDate().toString(),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        );
      }

      // 🚨 Fallback if no known structure
      return ListTile(
        title: Text('Unknown notification type'),
        subtitle: Text(data.toString()),
      );
    } catch (e) {
      return ListTile(
        title: Text('Error displaying notification'),
        subtitle: Text(e.toString()),
      );
    }
  }).toList(),
);

        },
      ),
    );
  }
}
