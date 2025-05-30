import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final List<Map<String, dynamic>> allBooks;

  const BookDetailPage({
    super.key,
    required this.bookData,
    required this.allBooks,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  bool _isBookmarked = false;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    if (userId == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('user-database')
            .doc(userId)
            .collection('book-mark')
            .doc(widget.bookData['title'])
            .get();

    setState(() {
      _isBookmarked = doc.exists;
    });
  }

  Future<void> _toggleBookmark() async {
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('user-database')
        .doc(userId)
        .collection('book-mark')
        .doc(widget.bookData['title']);

    if (_isBookmarked) {
      // Remove from Firestore
      await docRef.delete();
      _logger.i('Bookmark removed: ${widget.bookData['title']}');
    } else {
      // Save to Firestore
      await docRef.set({
        'title': widget.bookData['title'],
        'author': widget.bookData['author'],
        'cover-image-url': widget.bookData['cover-image-url'],
      });
      _logger.i('Bookmarked: ${widget.bookData['title']}');
    }

    setState(() {
      _isBookmarked = !_isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.bookData['cover-image-url']?.isNotEmpty == true
            ? widget.bookData['cover-image-url']
            : 'https://via.placeholder.com/150';
    final genre = widget.bookData['genre'];
    final sameGenreBooks =
        widget.allBooks
            .where(
              (book) =>
                  book['genre'] == genre &&
                  book['title'] != widget.bookData['title'],
            )
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color: _isBookmarked ? Colors.red : Colors.grey,
              size: 30,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.comment_outlined, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        _logger.e('Failed to load cover image', error: error);
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  widget.bookData['title'] ?? '',
                  style: GoogleFonts.concertOne(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF987554),
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'by ${widget.bookData['author'] ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoItem(label: 'Genre', value: genre ?? '-'),
                      _VerticalDivider(),
                      _InfoItem(
                        label: 'Year',
                        value:
                            widget.bookData['year-published']?.toString() ??
                            '-',
                      ),
                      _VerticalDivider(),
                      _InfoItem(
                        label: 'Publisher',
                        value: widget.bookData['publisher'] ?? '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.bookData['description'] != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    widget.bookData['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade400, thickness: 1),
                const SizedBox(height: 10),
                Text(
                  "If you like this book, You may like",
                  style: GoogleFonts.concertOne(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF987554),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                sameGenreBooks.isNotEmpty
                    ? SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sameGenreBooks.length,
                        itemBuilder: (context, index) {
                          final book = sameGenreBooks[index];
                          final recImageUrl =
                              book['cover-image-url']?.isNotEmpty == true
                                  ? book['cover-image-url']
                                  : 'https://via.placeholder.com/80';
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BookDetailPage(
                                        bookData: book,
                                        allBooks: widget.allBooks,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  recImageUrl,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    _logger.e(
                                      'Failed to load recommended image',
                                      error: error,
                                    );
                                    return Container(
                                      width: 80,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    : const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'No recommendations available',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      width: 2,
      color: Colors.grey.shade300,
    );
  }
}
