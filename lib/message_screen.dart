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
    var userDoc =
        await _firestore.collection('users').doc(widget.otherUserId).get();
    return userDoc['user_name'] ?? 'Unknown';
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
        'reaction': null, // No reaction initially
      });

      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    markMessagesAsRead();
  }

  void markMessagesAsRead() async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.${widget.currentUserId}': 0,
    });

    var messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: widget.currentUserId)
        .get();
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

  // Display reaction options in a bottom sheet
  void _showReactionOptions(String messageId) {
    List<String> reactions = ['❤️', '👍', '😂', '😮', '😢', '😡'];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 150,
          child: ListView(
            children: reactions.map((reaction) {
              return ListTile(
                title: Text(reaction, style: TextStyle(fontSize: 24)),
                onTap: () {
                  _updateReaction(messageId, reaction);
                  Navigator.pop(context); // Close the bottom sheet
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Display reaction button
  Widget _reactionButtons(String messageId, String? selectedReaction) {
    return GestureDetector(
      onTap: () =>
          _showReactionOptions(messageId), // Show reaction options on tap
      child: Text(
        selectedReaction ?? '+', // Display 'No reaction' if none is selected
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
                return Text('Chat with ${snapshot.data}');
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

                    // Check if the reaction is null or empty
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
                                doc.id, selectedReaction), // Show reaction
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