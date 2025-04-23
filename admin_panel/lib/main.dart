import 'package:admin_panel/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

import 'screens/dashboard_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/places_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/reviews',
              builder: (context, state) => const ReviewsScreen(),
            ),
            GoRoute(
              path: '/places',
              builder: (context, state) => const PlacesScreen(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
  routerConfig: router,
  title: 'Admin Panel',
  theme: ThemeData(
    primarySwatch: Colors.deepOrange,
    useMaterial3: true, 
  ),
  debugShowCheckedModeBanner: false,
);
  }
}