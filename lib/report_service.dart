import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportReview(String reviewId, String reportDescription, String reportType, BuildContext context) async {
    try {
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to report a review'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
        );
        return;
      }

      final reportRef = _firestore.collection('reports').doc();
      await reportRef.set({
        'Report_Description': reportDescription,
        'Report_Type': reportType,
        'Report_Date': FieldValue.serverTimestamp(),
        'Status': 'Pending',
        'ReportedBy': userId,
        'Review_ID': reviewId,
        'Report_Target_Type': 'Review',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review has been reported'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
      );
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pop(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report review'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
      );
    }
  }

void navigateToReportScreen(BuildContext context, String targetId, String targetType) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReportPage(targetId: targetId, targetType: targetType),
    ),
  );
}

Future<void> reportUser(String reportedUserId, String reportDescription, String reportType, BuildContext context) async {
  try {
    String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to report a user')),
      );
      return;
    }

    final reportRef = _firestore.collection('reports').doc();
    await reportRef.set({
      'Report_Description': reportDescription,
      'Report_Type': reportType,
      'Report_Date': FieldValue.serverTimestamp(),
      'Status': 'Pending',
      'ReportedBy': userId,
      'User_ID': reportedUserId,
      'Report_Target_Type': 'User',
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User has been reported')));
    Navigator.of(context).pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report user')));
  }
}

Future<void> reportPlace(String placeId, String reportDescription, String reportType, BuildContext context) async {
  try {
    String? userId = _auth.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to report a place')),
      );
      return;
    }

    final reportRef = _firestore.collection('reports').doc();
    await reportRef.set({
      'Report_Description': reportDescription,
      'Report_Type': reportType,
      'Report_Date': FieldValue.serverTimestamp(),
      'Status': 'Pending',
      'ReportedBy': userId,
      'Place_ID': placeId,
      'Report_Target_Type': 'Place',
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Place has been reported')));
    Navigator.of(context).pop();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report place')));
  }
}
}

class ReportPage extends StatefulWidget {
  final String targetId;
  final String targetType; 

  ReportPage({required this.targetId, required this.targetType});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String reportDescription = '';
  String reportType = 'Inappropriate content';
  final ReportService _reportService = ReportService();

  void _submitReport(BuildContext context) {
    if (widget.targetType == 'Review') {
      _reportService.reportReview(widget.targetId, reportDescription, reportType, context);
    } else if (widget.targetType == 'User') {
      _reportService.reportUser(widget.targetId, reportDescription, reportType, context);
    } else if (widget.targetType == 'Place') {
      _reportService.reportPlace(widget.targetId, reportDescription, reportType, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.targetType}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select report type:', style: Theme.of(context).textTheme.titleMedium),
            DropdownButton<String>(
              value: reportType,
              isExpanded: true,
              onChanged: (newType) {
                if (newType != null) {
                  setState(() => reportType = newType);
                }
              },
              items: ['Inappropriate content', 'Spam', 'Harassment']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
            ),
            SizedBox(height: 16),
            Text('Description:', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              onChanged: (value) => reportDescription = value,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a short note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF800020)),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () => _submitReport(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF800020)),
                  child: const Text("Report", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}