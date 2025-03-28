import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppTheme.primaryColor,
            child: Column(
              children: [
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.white),
                  title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white),
                  title: const Text("Users", style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text("Settings", style: TextStyle(color: Colors.white)),
                  onTap: () {},
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text("Sign Out", style: TextStyle(color: Colors.white)),
                  onTap: () => context.go('/'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dashboard", style: Theme.of(context).textTheme.headlineSmall),
                      Text("Welcome, Admin", style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text("Admin Dashboard Content goes here"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}