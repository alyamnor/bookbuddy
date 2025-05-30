//forgot.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
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
      Get.snackbar('Error', 'Please enter an email address',
          snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Error', e.message ?? 'Password reset failed',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: 'Enter email',
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: reset,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Send Reset Link'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Get.to(() => const Login(), transition: Transition.leftToRight),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}