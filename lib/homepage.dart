/*// homepage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.snackbar('Success', 'Signed out successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign out');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Homepage')),
      body: Center(child: Text('Welcome, ${user.email}')),
      floatingActionButton: FloatingActionButton(
        onPressed: signOut,
        child: const Icon(Icons.logout_rounded),
      ),
    );
  }
}

*/