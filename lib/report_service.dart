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

  void navigateToReportScreen(BuildContext context, String reviewId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPage(reviewId: reviewId),
      ),
    );
  }
}

class ReportPage extends StatefulWidget {
  final String reviewId;

  ReportPage({required this.reviewId});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String reportDescription = '';
  String reportType = 'Inappropriate content';
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter description:', style: Theme.of(context).textTheme.titleMedium),
            TextField(
              onChanged: (value) {
                reportDescription = value;
              },
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16),
            Text('Select report type:'),
            DropdownButton<String>(
              value: reportType,
              onChanged: (newType) {
                if (newType != null) {
                  setState(() {
                    reportType = newType;
                  });
                }
              },
              items: <String>['Inappropriate content', 'Spam', 'Harassment']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF800020)
                  ),
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _reportService.reportReview(widget.reviewId, reportDescription, reportType, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF800020)
                  ),
                  child: Text("Report", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}