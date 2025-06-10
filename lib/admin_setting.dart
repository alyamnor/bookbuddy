import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

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
      final doc =
          await FirebaseFirestore.instance
              .collection('user-database')
              .doc(user!.uid)
              .collection('profile')
              .doc('info')
              .get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? user!.displayName ?? '';
          _emailController.text = doc.data()?['email'] ?? user!.email ?? '';
        });
      }
    } catch (e) {
      _logger.e('Error fetching profile', error: e);
      Fluttertoast.showToast(msg: 'Failed to load profile');
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
          .collection('profile')
          .doc('info')
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      Fluttertoast.showToast(msg: 'Profile updated successfully');
      _logger.i('Profile updated for user: ${user!.uid}');
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
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
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
        title: Text(
          'Settings',
          style: GoogleFonts.concertOne(
            fontSize: 20,
            color: const Color(0xFF987554),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child:
            user == null
                ? const Center(child: Text('Please log in to view settings'))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profile',
                        style: GoogleFonts.concertOne(
                          fontSize: 18,
                          color: const Color(0xFF987554),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
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
                                  validator:
                                      (value) =>
                                          value!.trim().isEmpty
                                              ? 'Name is required'
                                              : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
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
                                    if (value!.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value.trim())) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Color(0xFF987554),
                                    )
                                    : ElevatedButton(
                                      onPressed: _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF987554,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text(
                                        'Save Changes',
                                        style: GoogleFonts.concertOne(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: TextButton(
                          onPressed: _signOut,
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.concertOne(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}