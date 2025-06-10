//main_navigation.dart
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'my_image_picker.dart';
import 'admin_book_grid_category.dart';
import 'admin_profile_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminBookGridByCategory(),
    const MyImagePicker(),
    const AdminProfileScreen(),
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
