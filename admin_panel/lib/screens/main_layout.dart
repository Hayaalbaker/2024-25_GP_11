import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.last.matchedLocation;

    Widget sidebarButton({
      required String label,
      required IconData icon,
      required String route,
    }) {
      final isSelected = currentRoute == route;
      return ListTile(
        leading: Icon(icon, color: isSelected ? Colors.amber : Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.amber : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
        onTap: () {
          if (!isSelected) context.go(route);
        },
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppTheme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("Welcome, Admin", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
                sidebarButton(label: "Dashboard", icon: Icons.dashboard, route: "/dashboard"),
                sidebarButton(label: "Reviews", icon: Icons.rate_review, route: "/reviews"),
                sidebarButton(label: "Places", icon: Icons.place, route: "/places"),
                sidebarButton(label: "Users", icon: Icons.person, route: "/users"),
                const Spacer(),
                sidebarButton(label: "Sign Out", icon: Icons.logout, route: "/"),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Main Page Area
          Expanded(child: child),
        ],
      ),
    );
  }
}