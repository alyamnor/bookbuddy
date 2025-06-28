import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class AdminSettingPage extends StatefulWidget {
  const AdminSettingPage({super.key});

  @override
  AdminSettingPageState createState() => AdminSettingPageState();
}

class AdminSettingPageState extends State<AdminSettingPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  Uint8List? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user-database')
          .doc(user!.uid)
          .get(); // Fetch from root user-database
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['preferredName'] ?? user!.displayName ?? '';
          _emailController.text = doc.data()?['email'] ?? user!.email ?? '';
          final profilePicture = doc.data()?['profilePicture'] as String?;
          if (profilePicture != null && profilePicture.isNotEmpty) {
            _profileImage = base64Decode(profilePicture);
          }
        });
      }
    } catch (e) {
      _logger.e('Error fetching profile', error: e);
      Fluttertoast.showToast(msg: 'Failed to load profile');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        Fluttertoast.showToast(msg: 'No image selected');
        return;
      }

      final bytes = await image.readAsBytes();
      setState(() {
        _profileImage = bytes;
      });

      Fluttertoast.showToast(msg: 'Image updated');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please log in');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await user!.updateDisplayName(_nameController.text.trim());
      if (_emailController.text.trim() != user!.email) {
        await user!.verifyBeforeUpdateEmail(_emailController.text.trim());
        Fluttertoast.showToast(
          msg: 'Verification email sent. Please verify your new email.',
        );
      }

      await FirebaseFirestore.instance
          .collection('user-database')
          .doc(user!.uid)
          .set({
            'preferredName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'profilePicture': _profileImage != null ? base64Encode(_profileImage!) : null,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      Fluttertoast.showToast(msg: 'Profile updated successfully');
      _logger.i('Profile updated for user: ${user!.uid}');
      Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      _logger.e('Error updating profile', error: e);
      Fluttertoast.showToast(msg: 'Failed to update profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(msg: 'Signed out successfully');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _logger.e('Error signing out', error: e);
      Fluttertoast.showToast(msg: 'Failed to sign out');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF987554)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BookBuddy',
          style: GoogleFonts.concertOne(
            fontSize: 30,
            color: const Color(0xFF987554),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5E8C7),
        elevation: 0,
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please log in to view settings'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null ? MemoryImage(_profileImage!) : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person, size: 60, color: Colors.brown)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 39, 215, 223),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF987554),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.rubik(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF987554),
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value!.trim().isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF987554)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.rubik(
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF987554),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF987554),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save',
                                    style: GoogleFonts.rubik(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
             
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}