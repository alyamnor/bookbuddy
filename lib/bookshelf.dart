import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail.dart'; // Import your BookDetailPage

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  _BookshelfPageState createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> userBooks = [];

  @override
  void initState() {
    super.initState();
    _fetchUserBooks();
  }

  Future<void> _fetchUserBooks() async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to view your bookshelf');
      return;
    }
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('user-books')
              .doc(userId)
              .collection('read-books')
              .get();

      setState(() {
        userBooks = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load bookshelf');
    }
  }

  Future<void> _addBook() async {
    if (userId == null) return;

    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final reviewController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Read Book'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
                TextField(
                  controller: reviewController,
                  decoration: const InputDecoration(labelText: 'Review'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final bookRef =
                        await FirebaseFirestore.instance
                            .collection('book-database')
                            .where(
                              'title',
                              isEqualTo: titleController.text.trim(),
                            )
                            .limit(1)
                            .get();
                    String? coverImageUrl;
                    if (bookRef.docs.isNotEmpty) {
                      coverImageUrl =
                          bookRef.docs.first.data()['cover-image-url'];
                    }

                    await FirebaseFirestore.instance
                        .collection('user-books')
                        .doc(userId)
                        .collection('read-books')
                        .doc(titleController.text.trim())
                        .set({
                          'title': titleController.text.trim(),
                          'author': authorController.text.trim(),
                          'cover-image-url':
                              coverImageUrl ??
                              'https://via.placeholder.com/150',
                          'review': reviewController.text.trim(),
                        });

                    if (reviewController.text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('book-comments')
                          .doc(titleController.text.trim())
                          .collection('comments')
                          .add({
                            'userId': userId,
                            'comment': reviewController.text.trim(),
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                    }

                    _fetchUserBooks();
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Book added to bookshelf');
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookshelf',
          style: GoogleFonts.concertOne(
            fontSize: 20,
            color: const Color(0xFF987554),
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF987554)),
            onPressed: _addBook,
          ),
        ],
      ),
      body: SafeArea(
        child:
            userBooks.isEmpty
                ? const Center(child: Text('No books on your bookshelf yet'))
                : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: userBooks.length,
                  itemBuilder: (context, index) {
                    final book = userBooks[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BookDetailPage(
                                  bookData: book,
                                  allBooks: [],
                                  processedImage: null,
                                ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    book['cover-image-url'] ??
                                    'https://via.placeholder.com/150',
                                fit: BoxFit.cover,
                                errorWidget:
                                    (context, url, error) =>
                                        const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            book['title'] ?? 'Unknown Title',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.concertOne(
                              fontSize: 16,
                              color: const Color(0xFF987554),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
