import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'book_grid_category.dart';
import 'main_navigation.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Uint8List? _parseImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e, stackTrace) {
      _logger.e('Error decoding image', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed('/login'); // Navigate to login screen after sign out
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No user logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Scaffold(
                      body: BookGridByCategory(),
                      bottomNavigationBar: MainNavigation(),
                    ),
              ),
            );
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
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
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        imageBytes != null ? MemoryImage(imageBytes) : null,
                    child:
                        imageBytes == null
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
                    style: GoogleFonts.concertOne(
                      textStyle: const TextStyle(
                        fontSize: 37,
                        color: Color(0xFF987554),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _buildListTile(Icons.library_books, 'Bookshelf', () {}),
                  const Divider(height: 1),
                  _buildListTile(Icons.bookmark, 'Bookmark', () {}),
                  const Divider(height: 1),
                  _buildListTile(Icons.settings, 'Account settings', () {}),
                  const Divider(height: 1),
                  _buildListTile(
                    Icons.logout,
                    'Log out',
                    _signOut,
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

  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.brown,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color == Colors.red ? color : Colors.black),
      ),
      onTap: onTap,
    );
  }
}
