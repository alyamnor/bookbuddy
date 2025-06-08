import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'book_detail.dart';

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
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to view your bookshelf');
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user-database')
          .doc(userId)
          .collection('book-shelf')
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
    double rating = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Color(0xFF987554),
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
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
                if (titleController.text.isNotEmpty && rating >= 1) {
                  final bookRef = await FirebaseFirestore.instance
                      .collection('book-database')
                      .where('title', isEqualTo: titleController.text.trim())
                      .limit(1)
                      .get();
                  if (bookRef.docs.isEmpty) {
                    Fluttertoast.showToast(msg: 'Book not found in database');
                    return;
                  }

                  final bookDoc = bookRef.docs.first;
                  final bookId = bookDoc.id;
                  final bookData = bookDoc.data();

                  await FirebaseFirestore.instance
                      .collection('user-database')
                      .doc(userId)
                      .collection('book-shelf')
                      .doc(bookId)
                      .set({
                        'bookId': bookId,
                        'title': titleController.text.trim(),
                        'author': authorController.text.trim(),
                        'cover-image-url': bookData['cover-image-url'] ?? 'https://via.placeholder.com/150',
                        'review': reviewController.text.trim(),
                        'genre': bookData['genre'] ?? '',
                        'rating': rating.toInt(),
                      });

                  // Store rating
                  await FirebaseFirestore.instance
                      .collection('user-database')
                      .doc(userId)
                      .collection('ratings')
                      .doc(bookId)
                      .set({
                        'rating': rating.toInt(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  if (reviewController.text.trim().isNotEmpty) {
                    await FirebaseFirestore.instance
                      .collection('book-database')
                      .doc(bookId)
                      .collection('book-comments')
                      .doc('book-review')
                      .collection('comments')
                      .add({
                        'userId': userId,
                        'comment': reviewController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                  }
                  _fetchBooks();
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: 'Book added to bookshelf');
                } else {
                  Fluttertoast.showToast(msg: 'Please provide a title and rating');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
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
        child: userBooks.isEmpty
            ? const Center(child: Text('No books on your bookshelf yet'))
            : GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: userBooks.length,
                itemBuilder: (context, index) {
                  final book = userBooks[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailPage(
                          bookData: book,
                          allBooks: [],
                          processedImage: null,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: book['cover-image-url'] ?? 'https://via.placeholder.com/150',
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
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
                        const SizedBox(height: 5),
                        RatingBarIndicator(
                          rating: (book['rating'] ?? 0).toDouble(),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Color(0xFF987554),
                          ),
                          itemCount: 5,
                          itemSize: 20,
                          direction: Axis.horizontal,
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