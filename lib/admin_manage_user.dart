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
      final snapshot =
          await FirebaseFirestore.instance.collection('user-database').get();

      setState(() {
        allUsers = snapshot.docs
            .where((doc) => doc.id != userId) // Exclude current user
            .map(
              (doc) => {
                'uid': doc.id,
                'preferredName': doc.data()['preferredName'] ?? '',
                'email': doc.data()['email'] ?? '',
              },
            )
            .toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load users');
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['preferredName']);
    final emailController = TextEditingController(text: user['email']);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(70),
                topRight: Radius.circular(70),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Edit User',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF987554),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Preferred Name',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.rubik(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (nameController.text.isNotEmpty &&
                            emailController.text.isNotEmpty) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('user-database')
                                .doc(user['uid'])
                                .update({
                              'preferredName':
                                  nameController.text.trim(),
                              'email': emailController.text.trim(),
                            });
                            _fetchUsers();
                            Navigator.pop(context);
                            Fluttertoast.showToast(
                              msg: 'User updated successfully',
                            );
                          } catch (e) {
                            Fluttertoast.showToast(
                              msg: 'Failed to update user',
                            );
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: 'Please fill all fields');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF987554),
                          border: Border.all(
                              color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.rubik(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Manage Users',
                style: GoogleFonts.rubik(
                  fontSize: 30,
                  color: const Color(0xFF987554),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: allUsers.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final user = allUsers[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: Colors.black, width: 1.0),
                          ),
                          color: Colors.white,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(12.0),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF987554),
                              child:
                                  Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              user['preferredName'],
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                color: const Color(0xFF987554),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              user['email'],
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF987554),
                                  ),
                                  onPressed: () => _editUser(user),
                                ),
                              ],
                            ),
                            onTap: () => _editUser(user),
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