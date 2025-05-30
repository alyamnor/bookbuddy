// wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookbuddy/main_navigation.dart';
import 'package:bookbuddy/login.dart';
import 'package:bookbuddy/verifyemail.dart';

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
        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: _checkEmailVerification(),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return verificationSnapshot.data == true
                  ? const MainNavigation()
                  : const VerifyEmail();
            },
          );
        }
        return const Login();
      },
    );
  }

  Future<bool> _checkEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false; // User is not logged in
  }
}