import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

// Simple string similarity function for fuzzy matching
double _stringSimilarity(String s1, String s2) {
  s1 = s1.toLowerCase();
  s2 = s2.toLowerCase();
  if (s1 == s2) return 1.0;
  int matches = 0;
  for (int i = 0; i < s1.length && i < s2.length; i++) {
    if (s1[i] == s2[i]) matches++;
  }
  return matches / (s1.length > s2.length ? s1.length : s2.length);
}

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  _BookshelfPageState createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> userBooks = [];
  DateTime? _selectedDate;

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
    _selectedDate = null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Add Read Book',
            style: GoogleFonts.concertOne(
              fontSize: 24,
              color: const Color(0xFF987554),
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: authorController,
                      decoration: InputDecoration(
                        labelText: 'Author',
                        labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: 'Review',
                        labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF987554),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select completion date'
                                  : DateFormat.yMMMd().format(_selectedDate!),
                              style: GoogleFonts.concertOne(
                                color: const Color(0xFF987554),
                              ),
                            ),
                            const Icon(Icons.calendar_today, color: Color(0xFF987554)),
                          ],
                        ),
                      ),
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
              );
            },
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
                if (titleController.text.isNotEmpty && rating >= 1 && _selectedDate != null) {
                  // Fuzzy search for book
                  final bookQuery = await FirebaseFirestore.instance
                      .collection('book-database')
                      .get();
                  Map<String, dynamic>? bestMatch;
                  double highestSimilarity = 0.6; // Minimum similarity threshold

                  for (var doc in bookQuery.docs) {
                    final title = doc.data()['title'] as String;
                    final similarity = _stringSimilarity(title, titleController.text.trim());
                    if (similarity > highestSimilarity) {
                      highestSimilarity = similarity;
                      bestMatch = doc.data();
                      bestMatch['bookId'] = doc.id;
                    }
                  }

                  if (bestMatch == null) {
                    Fluttertoast.showToast(msg: 'Book not found in database');
                    return;
                  }

                  final bookId = bestMatch['bookId'];
                  await FirebaseFirestore.instance
                      .collection('user-database')
                      .doc(userId)
                      .collection('book-shelf')
                      .doc(bookId)
                      .set({
                    'bookId': bookId,
                    'title': bestMatch['title'],
                    'author': authorController.text.trim(),
                    'cover-image-url': bestMatch['cover-image-url'] ?? 'https://via.placeholder.com/150',
                    'review': reviewController.text.trim(),
                    'genre': bestMatch['genre'] ?? '',
                    'rating': rating.toInt(),
                    'completionDate': Timestamp.fromDate(_selectedDate!),
                  });

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
                  Fluttertoast.showToast(msg: 'Please provide title, rating, and completion date');
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBookDetails(Map<String, dynamic> book) async {
    final reviewController = TextEditingController(text: book['review']);
    double rating = book['rating'].toDouble();
    _selectedDate = book['completionDate'] != null
        ? (book['completionDate'] as Timestamp).toDate()
        : null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Stack(
            children: [
              Center(
                child: Text(
                  book['title'],
                  style: GoogleFonts.concertOne(
                    fontSize: 24,
                    color: const Color(0xFF987554),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFF987554)),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                          'Confirm Delete',
                          style: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                        ),
                        content: Text(
                          'Are you sure you want to remove this book from your bookshelf?',
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
                      await FirebaseFirestore.instance
                          .collection('user-database')
                          .doc(userId)
                          .collection('book-shelf')
                          .doc(book['bookId'])
                          .delete();
                      _fetchBooks();
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: 'Book removed from bookshelf');
                    }
                  },
                ),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CachedNetworkImage(
                      imageUrl: book['cover-image-url'],
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        labelText: 'Review',
                        labelStyle: GoogleFonts.concertOne(color: const Color(0xFF987554)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: const Color(0xFF987554), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF987554),
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF987554)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select completion date'
                                  : DateFormat.yMMMd().format(_selectedDate!),
                              style: GoogleFonts.concertOne(
                                color: const Color(0xFF987554),
                              ),
                            ),
                            const Icon(Icons.calendar_today, color: Color(0xFF987554)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: rating,
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
              );
            },
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
                await FirebaseFirestore.instance
                    .collection('user-database')
                    .doc(userId)
                    .collection('book-shelf')
                    .doc(book['bookId'])
                    .update({
                  'review': reviewController.text.trim(),
                  'rating': rating.toInt(),
                  'completionDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
                });

                if (reviewController.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('book-database')
                      .doc(book['bookId'])
                      .collection('book-comments')
                      .doc('book-review')
                      .collection('comments')
                      .add({
                    'userId': userId,
                    'comment': reviewController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                await FirebaseFirestore.instance
                    .collection('user-database')
                    .doc(userId)
                    .collection('ratings')
                    .doc(book['bookId'])
                    .set({
                  'rating': rating.toInt(),
                  'timestamp': FieldValue.serverTimestamp(),
                });

                _fetchBooks();
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Book updated');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF987554)),
            onPressed: _addBook,
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
                'My Bookshelf',
                style: GoogleFonts.concertOne(
                  fontSize: 32,
                  color: const Color(0xFF987554),
                ),
              ),
            ),
            Expanded(
              child: userBooks.isEmpty
                  ? const Center(child: Text('No books on your bookshelf yet'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: userBooks.length,
                      itemBuilder: (context, index) {
                        final book = userBooks[index];
                        return GestureDetector(
                          onTap: () => _showBookDetails(book),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: book['cover-image-url'] ?? 'https://via.placeholder.com/150',
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                              ),
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