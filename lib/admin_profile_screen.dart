
import 'package:bookbuddy/admin_setting.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'admin_book_grid_category.dart';
import 'main_navigation.dart';
import 'package:logger/logger.dart';
import 'admin_manage_event.dart';
import 'admin_manage_user.dart';

final Logger _logger = Logger();

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  Uint8List? _parseImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e, stackTrace) {
      _logger.e('Error decoding image', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Confirm Log Out',
              style: GoogleFonts.rubik(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF987554),
                ),
              ),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Confirm',
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

      // Proceed with sign out only if confirmed
      if (confirm == true) {
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login'); // Navigate to login screen after sign out
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BookBuddy",
          style: GoogleFonts.concertOne(
            textStyle: const TextStyle(
              fontSize: 30,
              color: Color(0xFF987554),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF987554)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: AdminBookGridByCategory(),
                  bottomNavigationBar: MainNavigation(),
                ),
              ),
            );
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('user-database')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No user data found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final preferredName = data['preferredName'] ?? 'User';
          final email = data['email'] ?? user.email ?? 'No email';
          final profilePicture = data['profilePicture'] as String?;
          final imageBytes = _parseImage(profilePicture);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.brown,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    preferredName,
                    style: GoogleFonts.rubik(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF987554),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.rubik(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildListTile(
                    icon: Icons.library_books,
                    title: 'Manage Users',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminManageUserPage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildListTile(
                    icon: Icons.bookmark,
                    title: 'Manage Events',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminManageEventPage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildListTile(
                    icon: Icons.settings,
                    title: 'Account settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSettingPage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  _buildListTile(
                    icon: Icons.logout,
                    title: 'Log out',
                    onTap: () => _signOut(context),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.brown,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.rubik(
          textStyle: TextStyle(
            color: color == Colors.red ? color : Color(0xFF987554),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}