import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'login.dart';
import 'verifyemail.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  File? _profileImage;
  bool isLoading = false;
  bool obscurePassword = true;
  final ImagePicker _picker = ImagePicker();
  String? selectedRole; // To store the selected role

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_profileImage == null) return null;
    try {
      final bytes = await _profileImage!.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        Get.snackbar('Warning', 'Image is too large (max 2MB)');
        return null;
      }
      return base64Encode(bytes);
    } catch (e) {
      Get.snackbar('Error', 'Failed to process image: $e');
      return null;
    }
  }

  Future<void> signUp() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        selectedRole == null) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields, including your role',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final String? userId = userCredential.user?.uid;
      if (userId != null) {
        final String? profileImageBase64 = await _convertImageToBase64();

        // Store user data in Firestore, including role
        await FirebaseFirestore.instance.collection('user-database').doc(userId).set({
          'email': emailController.text.trim(),
          'preferredName': nameController.text.trim(),
          'role': selectedRole, // Store the selected role
          if (profileImageBase64 != null) 'profilePicture': profileImageBase64,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await userCredential.user?.sendEmailVerification();
        Get.offAll(() => const VerifyEmail());
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message ?? 'Sign up failed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: const Color.fromRGBO(0, 0, 0, 0.7)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(height: 20),

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
                            'Join the world of books',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 40),

                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color.fromRGBO(255, 255, 255, 0.6),
                                  image: _profileImage != null
                                      ? DecorationImage(
                                          image: FileImage(_profileImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _profileImage == null
                                    ? const Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Colors.brown,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Preferred Name Field
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter preferred name',
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: const Color.fromRGBO(255, 255, 255, 0.6),
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
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter email',
                              prefixIcon: const Icon(Icons.email),
                              filled: true,
                              fillColor: const Color.fromRGBO(255, 255, 255, 0.6),
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
                          const SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: const Color.fromRGBO(255, 255, 255, 0.6),
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
                          ),
                          const SizedBox(height: 16),

                          // Role Selection Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedRole,
                            hint: const Text('Select your role'),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.group),
                              filled: true,
                              fillColor: const Color.fromRGBO(255, 255, 255, 0.6),
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
                            items: ['Reader', 'Librarian'].map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedRole = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: 0.7,
                              child: ElevatedButton(
                                onPressed: signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Sign Up'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: TextButton(
                                  onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ),
                              );
                            },
                              child: const Text(
                                'Already have an account? Login',
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}