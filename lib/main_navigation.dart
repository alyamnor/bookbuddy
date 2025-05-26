import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'book_grid_category.dart';
import 'book_recognition.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BookGridByCategory(),
    const MyImagePicker(),
    const ProfileScreen(),
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
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
