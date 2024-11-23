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

                String reviewId = data['reviewId'] ?? '';

                if (reviewId.isEmpty) {
                  return ListTile(
                    title: Text('No review ID found'),
                    subtitle: Text('Invalid notification data'),
                  );
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Review')
                      .doc(reviewId)
                      .get(),
                  builder: (context,
                      AsyncSnapshot<DocumentSnapshot> reviewSnapshot) {
                    if (reviewSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Loading review data...'),
                      );
                    }
                    if (reviewSnapshot.hasError || !reviewSnapshot.hasData) {
                      return ListTile(
                        title: Text('Error loading review data'),
                      );
                    }

                    Map<String, dynamic>? reviewData =
                        reviewSnapshot.data!.data() as Map<String, dynamic>?;
                    if (reviewData == null) {
                      return ListTile(
                        title: Text('Review not found'),
                      );
                    }

                    List<dynamic> likeCount = reviewData['Like_count'] ?? [];
                    if (likeCount.isEmpty) {
                      return ListTile(
                        title: Text('No likes yet'),
                        subtitle:
                            Text(reviewData['Review_Text'] ?? 'No review text'),
                      );
                    }

                    String firstUserId = likeCount[0];
                    int othersCount = likeCount.length - 1;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(firstUserId)
                          .get(),
                      builder: (context,
                          AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Loading user info...'),
                          );
                        }
                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return ListTile(
                            title: Text('Error loading user info'),
                          );
                        }

                        String firstUserName =
                            userSnapshot.data!.get('user_name') ?? 'Someone';
                        String notificationText = othersCount > 0
                            ? '$firstUserName and $othersCount others liked your review'
                            : '$firstUserName liked your review';

                        return ListTile(
                          leading: Icon(Icons.notifications),
                          title: Text(notificationText),
                          subtitle: Text(
                            reviewData['Review_Text'] ?? 'No review text',
                            style: TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            (data['timestamp'] as Timestamp)
                                .toDate()
                                .toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
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
