import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'book_detail.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  _BookmarkPageState createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> bookmarks = [];

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to view bookmarks');
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user-database')
          .doc(userId)
          .collection('bookmarks')
          .get();

      setState(() {
        bookmarks = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      _logger.e('Error fetching bookmarks', error: e);
      Fluttertoast.showToast(msg: 'Failed to load bookmarks');
    }
  }

  Future<void> _removeBookmark(String bookId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Remove Bookmark',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: const Color(0xFF987554),
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$title" from your bookmarks?',
          style: GoogleFonts.poppins(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF987554)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: const Color(0xFFFF0000)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('user-database')
            .doc(userId)
            .collection('bookmarks')
            .doc(bookId)
            .delete();
        _fetchBookmarks();
        Fluttertoast.showToast(msg: 'Bookmark removed');
      } catch (e) {
        _logger.e('Error removing bookmark', error: e);
        Fluttertoast.showToast(msg: 'Failed to remove bookmark');
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullBookData(String bookId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('book-database')
          .doc(bookId)
          .get();
      return doc.exists ? doc.data()! : {};
    } catch (e) {
      _logger.e('Error fetching full book data', error: e);
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F5F0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'My Bookmark',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: const Color(0xFF987554),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: bookmarks.isEmpty
                    ? const Center(child: Text('No bookmarks yet'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final book = bookmarks[index];
                          final bookId = book['bookId'] ?? book['title'];
                          return GestureDetector(
                            onTap: () async {
                              final fullBookData = await _fetchFullBookData(bookId);
                              if (fullBookData.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailPage(
                                      bookData: {
                                        ...book,
                                        ...fullBookData,
                                      },
                                      allBooks: bookmarks,
                                      searchType: 'category',
                                    ),
                                  ),
                                );
                              } else {
                                Fluttertoast.showToast(msg: 'Failed to load book details');
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey, width: 1.0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                    child: CachedNetworkImage(
                                      imageUrl: book['cover-image-url'] ?? 'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      height: 120,
                                      width: double.infinity,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        _logger.e('Failed to load bookmark image', error: error);
                                        return const Icon(Icons.broken_image, size: 50);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                book['title'] ?? 'Unknown Title',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  color: const Color(0xFF000000),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'by ${book['author'] ?? 'Unknown Author'}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                book['store'] ?? 'Unknown Store',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.bookmark,
                                            color: Color(0xFFFF0000),
                                          ),
                                          onPressed: () => _removeBookmark(bookId, book['title'] ?? 'Unknown Title'),
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
      ),
    );
  }
}