import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalReports = 0;
  int resolvedReports = 0;
  int userReports = 0;
  int reviewReports = 0;
  int placeReports = 0;
  int totalUsers = 0;
  int totalPlaces = 0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final reportSnapshot = await FirebaseFirestore.instance.collection('reports').get();
    final resolvedSnapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('Status', whereIn: ['Warning Sent', 'Deleted'])
        .get();

    final userSnap = await FirebaseFirestore.instance.collection('users').get();
    final placeSnap = await FirebaseFirestore.instance.collection('places').get();
    final reviewSnap = await FirebaseFirestore.instance.collection('Review').get();

    final reports = reportSnapshot.docs;
    int userCount = 0;
    int placeCount = 0;
    int reviewCount = 0;

    for (var doc in reports) {
      final type = doc['Report_Target_Type'] ?? 'Review';
      if (type == 'User') {
        userCount++;
      } else if (type == 'Place') {
        placeCount++;
      } else {
        reviewCount++;
      }
    }

    setState(() {
      totalReports = reports.length;
      resolvedReports = resolvedSnapshot.size;
      userReports = userCount;
      placeReports = placeCount;
      reviewReports = reviewCount;
      totalUsers = userSnap.size;
      totalPlaces = placeSnap.size;
      totalReviews = reviewSnap.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    double resolutionRate = totalReports == 0 ? 0 : (resolvedReports / totalReports) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader("Dashboard"),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.people, "Users", totalUsers, Colors.teal)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(Icons.location_on, "Places", totalPlaces, Colors.deepPurple)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.reviews, "Reviews", totalReviews, Colors.indigo)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(Icons.flag, "Total Reports", totalReports, Colors.red)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.check, "Resolved", resolvedReports, Colors.green)),
                  Expanded(child: _buildStatCard(Icons.percent, "Resolution %", resolutionRate.toStringAsFixed(1), Colors.orange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.person_off, "User Reports", userReports, Colors.cyan)),
                  Expanded(child: _buildStatCard(Icons.comment, "Review Reports", reviewReports, Colors.amber)),
                  Expanded(child: _buildStatCard(Icons.place, "Place Reports", placeReports, Colors.pink)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget sectionHeader(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
        ),
      ],
    ),
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}