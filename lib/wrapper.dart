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

        final user = snapshot.data;
        if (user != null) {
          return FutureBuilder<bool>(
            future: _checkEmailVerification(user),
            builder: (context, verificationSnapshot) {
              if (verificationSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final isVerified = verificationSnapshot.data ?? false;
              return isVerified ? const MainNavigation() : const VerifyEmail();
            },
          );
        }

        return const Login();
      },
    );
  }
}

// Separate helper function
Future<bool> _checkEmailVerification(User user) async {
  await user.reload(); // Refreshes user data
  return user.emailVerified;
}
