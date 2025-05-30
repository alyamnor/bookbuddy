import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'wrapper.dart';

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
          'Verification Link Sent',
          'A verification link has been sent to ${user.email}',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to send verification email',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> checkVerification() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        Get.offAll(() => const Wrapper());
      } else {
        Get.snackbar('Still Not Verified', 'Please check your email inbox.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not check verification status',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Black overlay
          Container(color: Colors.black.withOpacity(0.7)),

          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.offAll(() => const Wrapper()),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'BookBuddy',
                          style: GoogleFonts.concertOne(
                            textStyle: const TextStyle(
                              fontSize: 50,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 60, color: Colors.white),
                                const SizedBox(height: 16),
                                const Text(
                                  'A verification email has been sent to:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user?.email ?? 'your email address',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: ElevatedButton(
                                    onPressed: checkVerification,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('I\'ve Verified My Email'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: sendVerifyLink,
                                  child: const Text(
                                    'Resend Verification Email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Get.offAll(() => const Wrapper());
                                  },
                                  child: const Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
