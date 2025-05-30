import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> reset() async {
    if (emailController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an email address',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      Get.snackbar(
        'Success',
        'Password reset email sent. Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.off(() => const Login(), transition: Transition.leftToRight);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message ?? 'Password reset failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.7)),

          // Foreground
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
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
                          const Text(
                            'Recover your password',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Email Field
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter email',
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.brown,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 24),

                          // Reset Button (narrower)
                          Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: ElevatedButton(
                                onPressed: reset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Send Reset Link'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Back to login
                          Center(
                            child: TextButton(
                              onPressed:
                                  () => Get.to(
                                    () => const Login(),
                                    transition: Transition.leftToRight,
                                  ),
                              child: const Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 2,
                                ),
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

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
