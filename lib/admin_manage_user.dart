import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageUserPage extends StatefulWidget {
  const AdminManageUserPage({super.key});

  @override
  _AdminManageUserPageState createState() => _AdminManageUserPageState();
}

class _AdminManageUserPageState extends State<AdminManageUserPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to manage users');
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user-database')
          .get();

      setState(() {
        allUsers = snapshot.docs.map((doc) => {
          'uid': doc.id,
          'preferredName': doc.data()['preferredName'] ?? '',
          'email': doc.data()['email'] ?? '',
        }).toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load users');
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['preferredName']);
    final emailController = TextEditingController(text: user['email']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Edit User',
            style: GoogleFonts.concertOne(
              fontSize: 24,
              color: const Color(0xFF987554),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Preferred Name',
                    labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('user-database')
                        .doc(user['uid'])
                        .update({
                      'preferredName': nameController.text.trim(),
                      'email': emailController.text.trim(),
                    });
                    _fetchUsers();
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'User updated successfully');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Failed to update user');
                  }
                } else {
                  Fluttertoast.showToast(msg: 'Please fill all fields');
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Delete',
          style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
        ),
        content: Text(
          'Are you sure you want to delete this user?',
          style: GoogleFonts.concertOne(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('user-database')
            .doc(uid)
            .delete();
        _fetchUsers();
        Fluttertoast.showToast(msg: 'User deleted successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to delete user');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF987554)),
            onPressed: () {
              // Add new user functionality can be added here if needed
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Manage Users',
                style: GoogleFonts.concertOne(
                  fontSize: 32,
                  color: const Color(0xFF987554),
                ),
              ),
            ),
            Expanded(
              child: allUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final user = allUsers[index];
                        return GestureDetector(
                          onTap: () => _editUser(user),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Text(
                                        user['preferredName'],
                                        style: GoogleFonts.concertOne(
                                          fontSize: 16,
                                          color: const Color(0xFF987554),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteUser(user['uid']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}