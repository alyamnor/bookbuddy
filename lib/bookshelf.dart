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
      final snapshot =
          await FirebaseFirestore.instance
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Add What I’ve Read',
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
                        'Title',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.roboto(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
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
                        'Author',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
                    TextField(
                      controller: authorController,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.roboto(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
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
                        'Review',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.roboto(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
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
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select completion date'
                                  : DateFormat.yMMMd().format(_selectedDate!),
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF987554),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF987554),
                            ),
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
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.yellow),
                      onRatingUpdate: (value) {
                        rating = value;
                      },
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
                            if (titleController.text.isNotEmpty &&
                                rating >= 1 &&
                                _selectedDate != null) {
                              final bookQuery =
                                  await FirebaseFirestore.instance
                                      .collection('book-database')
                                      .get();
                              Map<String, dynamic>? bestMatch;
                              double highestSimilarity = 0.6;

                              for (var doc in bookQuery.docs) {
                                final title = doc.data()['title'] as String;
                                final similarity = _stringSimilarity(
                                  title,
                                  titleController.text.trim(),
                                );
                                if (similarity > highestSimilarity) {
                                  highestSimilarity = similarity;
                                  bestMatch = doc.data();
                                  bestMatch['bookId'] = doc.id;
                                }
                              }

                              if (bestMatch == null) {
                                Fluttertoast.showToast(
                                  msg: 'Book not found in database',
                                );
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
                                    'cover-image-url':
                                        bestMatch['cover-image-url'] ??
                                        'https://via.placeholder.com/150',
                                    'review': reviewController.text.trim(),
                                    'genre': bestMatch['genre'] ?? '',
                                    'rating': rating.toInt(),
                                    'completionDate': Timestamp.fromDate(
                                      _selectedDate!,
                                    ),
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

                              _fetchBooks();
                              Navigator.pop(context);
                              Fluttertoast.showToast(
                                msg: 'Book added to bookshelf',
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg:
                                    'Please provide title, rating, and completion date',
                              );
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
                                color: const Color(0xFF987554),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Add',
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
      },
    );
  }

  Future<void> _showBookDetails(Map<String, dynamic> book) async {
    final reviewController = TextEditingController(text: book['review']);
    double rating = book['rating'].toDouble();
    _selectedDate =
        book['completionDate'] != null
            ? (book['completionDate'] as Timestamp).toDate()
            : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      book['title'],
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
                        'Review',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
                    TextField(
                      controller: reviewController,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.roboto(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.grey,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF987554),
                        ),
                      ),
                    ),
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
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select completion date'
                                  : DateFormat.yMMMd().format(_selectedDate!),
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF987554),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF987554),
                            ),
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
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.yellow),
                      onRatingUpdate: (value) {
                        rating = value;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Text(
                                      'Delete Book',
                                      style: GoogleFonts.rubik(
                                        color: const Color(0xFF987554),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to remove this book from your bookshelf?',
                                      style: GoogleFonts.roboto(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.rubik(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: Text(
                                          'Delete',
                                          style: GoogleFonts.rubik(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                              await FirebaseFirestore.instance
                                  .collection('user-database')
                                  .doc(userId)
                                  .collection('ratings')
                                  .doc(book['bookId'])
                                  .delete();
                              _fetchBooks();
                              Navigator.pop(context);
                              Fluttertoast.showToast(
                                msg: 'Book removed from bookshelf',
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Delete',
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
                            await FirebaseFirestore.instance
                                .collection('user-database')
                                .doc(userId)
                                .collection('book-shelf')
                                .doc(book['bookId'])
                                .update({
                                  'review': reviewController.text.trim(),
                                  'rating': rating.toInt(),
                                  'completionDate':
                                      _selectedDate != null
                                          ? Timestamp.fromDate(_selectedDate!)
                                          : null,
                                });

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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF987554),
                              border: Border.all(
                                color: const Color(0xFF987554),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Edit',
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
            icon: const Icon(
              Icons.add_box_rounded,
              color: Color(0xFF987554),
              size: 30,
            ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookshelf',
                    style: GoogleFonts.rubik(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  userBooks.isEmpty
                      ? const Center(
                        child: Text(
                          'No books on your bookshelf yet',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: userBooks.length,
                        itemBuilder: (context, index) {
                          final book = userBooks[index];
                          return GestureDetector(
                            onTap: () => _showBookDetails(book),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 150,
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book['title'],
                                          style: GoogleFonts.rubik(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book['review'] ?? 'No review',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book['completionDate'] != null
                                              ? DateFormat.yMMMd().format(
                                                (book['completionDate']
                                                        as Timestamp)
                                                    .toDate(),
                                              )
                                              : 'No date',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        RatingBarIndicator(
                                          rating: book['rating'].toDouble(),
                                          itemBuilder:
                                              (context, _) => const Icon(
                                                Icons.star,
                                                color: Colors.yellow,
                                              ),
                                          itemCount: 5,
                                          itemSize: 20,
                                          direction: Axis.horizontal,
                                        ),
                                      ],
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
