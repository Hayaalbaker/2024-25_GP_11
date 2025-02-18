import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_screen.dart';
import 'AESHelper.dart';

class MessageListScreen extends StatelessWidget {
  final String currentUserId;

  MessageListScreen({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
                .orderBy('timestamp', descending: true) 

            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No conversations'));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> chatData =
                  doc.data() as Map<String, dynamic>;
              String otherUserId = (chatData['participants'] as List)
                  .firstWhere((id) => id != currentUserId);
              String decoders =
                  AESHelper.decryptMessage(chatData['lastMessage']);
              String lastMessage = decoders;
              Timestamp timestamp = chatData['timestamp'] ?? Timestamp.now();

              int unreadCount = 0;
              if (chatData['unreadCount'] is Map) {
                unreadCount = chatData['unreadCount'][currentUserId] ?? 0;
              } else {
                unreadCount =
                    0;
              }

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder:
                    (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Unknown'),
                      subtitle: Text(lastMessage),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageScreen(
                              currentUserId: currentUserId,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  String otherUsername =
                      userSnapshot.data!['user_name'] ?? 'Unknown';

                  return ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text(otherUsername),
                    subtitle: Text(lastMessage),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${timestamp.toDate().hour}:${timestamp.toDate().minute}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: EdgeInsets.only(top: 5),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageScreen(
                            currentUserId: currentUserId,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );

                      if (currentUserId == otherUserId) {
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(doc.id)
                            .update({
                          'unreadCount': 0,
                        });
                      }
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
