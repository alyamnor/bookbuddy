import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookbuddy/main_navigation.dart';
import 'package:bookbuddy/login.dart';
import 'package:bookbuddy/verifyemail.dart';
import 'package:bookbuddy/admin_main_navigation.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading authentication state')),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<bool>(
            future: _checkEmailVerification(user),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isVerified = verificationSnapshot.data ?? false;
              if (!isVerified) {
                return const VerifyEmail();
              }
              return FutureBuilder<String?>(
                future: _getUserRole(user),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final role = roleSnapshot.data;
                  if (role == 'Reader') {
                    return const MainNavigation();
                  } else if (role == 'Librarian') {
                    return const AdminMainNavigation();
                  } else {
                    return const Scaffold(
                      body: Center(child: Text('Error: User role not found')),
                    );
                  }
                },
              );
            },
          );
        }

        return const Login();
      },
    );
  }

  // Helper function to check email verification
  Future<bool> _checkEmailVerification(User user) async {
    await user.reload(); // Refreshes user data
    return user.emailVerified;
  }

  // Helper function to fetch user role from Firestore
  Future<String?> _getUserRole(User user) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('user-database')
              .doc(user.uid)
              .get();
      return userDoc.data()?['role'] as String?;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }
}
