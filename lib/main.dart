import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'book_grid_category.dart';
import 'profile_screen.dart'; // Import your profile screen
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'book_recognition.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    BookGridByCategory(),
    MyImagePicker(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: const Color(0xFFE5D3B3),
        items: const [
          Icon(Icons.home_filled, size: 30, color: Color(0xFF987554)),
          Icon(Icons.add_a_photo_sharp, size: 30, color: Color(0xFF987554)),
          Icon(Icons.person_2, size: 30, color: Color(0xFF987554)),
        ],
        index: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
