import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WarningService {
  static Future<void> sendWarning(
  BuildContext context,
  String userId,
  String reportId,
) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send Warning"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Enter warning message...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;

              final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
              final userEmail = userDoc['email'] ?? 'No email';
              final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';

              // Add to warnings collection
              await FirebaseFirestore.instance.collection('warnings').add({
                'userId': userId,
                'userEmail': userEmail,
                'message': message,
                'date': FieldValue.serverTimestamp(),
              });

              // Send the email
              await http.post(
                Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
                headers: {'origin': 'http://localhost', 'Content-Type': 'application/json'},
                body: json.encode({
                  'service_id': 'service_5lj8e5w',
                  'template_id': 'template_0qns40h',
                  'user_id': '0tNpevs6M08p6KJEJ',
                  'template_params': {'to_email': userEmail, 'message': message}
                }),
              );

              await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
                'Status': 'Warning Sent',
                'ReviewedBy': adminEmail,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Warning sent successfully")),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }
}