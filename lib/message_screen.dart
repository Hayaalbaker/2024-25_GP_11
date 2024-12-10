import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'AESHelper.dart';
import 'package:localize/profile_screen.dart';

class MessageScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  MessageScreen({required this.currentUserId, required this.otherUserId});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String get chatId => widget.currentUserId.compareTo(widget.otherUserId) < 0
      ? '${widget.currentUserId}_${widget.otherUserId}'
      : '${widget.otherUserId}_${widget.currentUserId}';

  Future<String> getUserName() async {
    try {
      var userDoc =
          await _firestore.collection('users').doc(widget.otherUserId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('user_name')) {
        return userDoc['user_name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching user_name: $e');
      return 'Unknown';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(fileName);

      await ref.putFile(imageFile);
      String imageUrl = await ref.getDownloadURL();
      _sendMessage(imageUrl);
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  void _sendMessage([String? imageUrl]) async {
    String messageText = _messageController.text;
    if (imageUrl != null) {
      messageText = imageUrl;
    }

    if (messageText.isNotEmpty) {
      var chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [widget.currentUserId, widget.otherUserId],
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'lastMessage': AESHelper.encryptMessage(messageText),
          'timestamp': FieldValue.serverTimestamp(),
          'unreadCount': {widget.otherUserId: 1, widget.currentUserId: 0},
        });
      } else {
        await _firestore.collection('chats').doc(chatId).update({
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'lastMessage': AESHelper.encryptMessage(messageText),
          'timestamp': FieldValue.serverTimestamp(),
          if (widget.currentUserId != widget.otherUserId)
            'unreadCount.${widget.otherUserId}': FieldValue.increment(1),
        });
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'receiverId': widget.otherUserId,
        'message': AESHelper.encryptMessage(messageText),
        'timestamp': FieldValue.serverTimestamp(),
        'reaction': null, 
      });

      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
 
   
     markMessagesAsRead();

  }


Future<void> checkAndCreateChat( ) async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  print('-------------------------');
  print(chatId);
  print('-------------------------');
  try {
    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    DocumentSnapshot chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      await chatRef.set({
          'timestamp': FieldValue.serverTimestamp(),
      });
        print('-------------------------');
      print('Chat created with ID: $chatId');
        print('-------------------------');
    } else {
        print('-------------------------');
      print('Chat already exists with ID: $chatId');
        print('-------------------------');
    }
  } catch (e) {
      print('-------------------------');
    print('Error checking or creating chat: $e');
      print('-------------------------');
  }
}

  void markMessagesAsRead() async {
 try {
   await checkAndCreateChat();
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.${widget.currentUserId}': 0,
    });

    var messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .get();
          } catch (e) {
    print('Error fetching messages: $e');
  }
  }

  void _updateReaction(String messageId, String reaction) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reaction': reaction,
    });
  }

  void _showReactionOptions(String messageId) {
    List<String> reactions = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 150,
          child: ListView(
            children: reactions.map((reaction) {
              return ListTile(
                title: Text(reaction, style: TextStyle(fontSize: 24)),
                onTap: () {
                  _updateReaction(messageId, reaction);
                  Navigator.pop(context); 
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _reactionButtons(String messageId, String? selectedReaction) {
    return GestureDetector(
      onTap: () =>
          _showReactionOptions(messageId),
      child: Text(
        selectedReaction ?? '+', 
        style: TextStyle(fontSize: 20, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.otherUserId),
              ),
            );
          },
          child: FutureBuilder<String>(
            future: getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading...');
              } else if (snapshot.hasError) {
                return Text('Error');
              } else {
                String userName = snapshot.data ?? 'Unknown';
                return Text(
                    'Chat with ${userName.isNotEmpty ? userName : "Unknown"}');
              }
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return ListView(
                  reverse: true,
                  children: snapshot.data!.docs.map((doc) {
                    var message = AESHelper.decryptMessage(doc['message']);
                    bool isMe = doc['senderId'] == widget.currentUserId;

                    String? selectedReaction = doc['reaction'];

                    return ListTile(
                      title: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: message.startsWith('http')
                                  ? Image.network(message)
                                  : Text(message),
                            ),
                            _reactionButtons(
                                doc.id, selectedReaction), 
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
