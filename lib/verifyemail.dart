// verifyemail.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:bookbuddy/wrapper.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    sendVerifyLink();
  }

  Future<void> sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
        Get.snackbar(
          'Link Sent',
          'A verification link has been sent to ${user.email}',
          margin: const EdgeInsets.all(30),
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to send verification email');
      }
    }
  }

  Future<void> checkVerification() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        Get.offAll(() => const Wrapper());
      } else {
        Get.snackbar('Info', 'Email not verified yet');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error checking verification status');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'A verification email has been sent to ${user?.email ?? "your email address"}. Please check your inbox and follow the link to verify your email.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: checkVerification,
                    child: const Text('I\'ve Verified My Email'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: sendVerifyLink,
                    child: const Text('Resend Verification Email'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Get.offAll(() => const Wrapper());
                    },
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
    );
  }
}
