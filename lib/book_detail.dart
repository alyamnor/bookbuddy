import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final List<Map<String, dynamic>> allBooks;
  final File? processedImage; // Added for preprocessed image

  const BookDetailPage({
    super.key,
    required this.bookData,
    required this.allBooks,
    this.processedImage,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  bool _isBookmarked = false;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  bool _showProcessedImage = false;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _fetchComments();
  }

  Future<void> _checkBookmarkStatus() async {
    if (userId == null) return;
    final doc = await FirebaseFirestore.instance
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
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to bookmark');
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection('user-database')
        .doc(userId)
        .collection('book-mark')
        .doc(widget.bookData['title']);

    try {
      if (_isBookmarked) {
        await docRef.delete();
        _logger.i('Bookmark removed: ${widget.bookData['title']}');
        Fluttertoast.showToast(msg: 'Bookmark removed');
      } else {
        await docRef.set({
          'title': widget.bookData['title'],
          'author': widget.bookData['author'],
          'cover-image-url': widget.bookData['cover-image-url'],
        });
        _logger.i('Bookmarked: ${widget.bookData['title']}');
        Fluttertoast.showToast(msg: 'Bookmarked');
      }
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (e) {
      _logger.e('Bookmark error', error: e);
      Fluttertoast.showToast(msg: 'Failed to update bookmark');
    }
  }

  Future<void> _fetchComments() async {
    if (userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('book-comments')
        .doc(widget.bookData['title'])
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _comments = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _addComment() async {
    if (userId == null || _commentController.text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('book-comments')
          .doc(widget.bookData['title'])
          .collection('comments')
          .add({
        'userId': userId,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _logger.i('Comment added for ${widget.bookData['title']}');
      _commentController.clear();
      await _fetchComments();
      Fluttertoast.showToast(msg: 'Comment added');
    } catch (e) {
      _logger.e('Comment error', error: e);
      Fluttertoast.showToast(msg: 'Failed to add comment');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.bookData['cover-image-url']?.isNotEmpty == true
        ? widget.bookData['cover-image-url']
        : 'https://via.placeholder.com/150';
    final genre = widget.bookData['genre'] ?? 'Unknown';
    final sameGenreBooks = widget.allBooks
        .where(
          (book) =>
              book['genre'] == genre && book['title'] != widget.bookData['title'],
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
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => _buildCommentSheet(),
              );
            },
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
                    child: _showProcessedImage && widget.processedImage != null
                        ? Image.file(
                            widget.processedImage!,
                            height: 300,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            height: 300,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              _logger.e('Failed to load cover image', error: error);
                              return const Icon(Icons.broken_image, size: 100);
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: widget.processedImage != null
                      ? () => setState(() => _showProcessedImage = !_showProcessedImage)
                      : null,
                  child: Text(
                    _showProcessedImage ? 'Show Original Image' : 'Show Processed Image',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  widget.bookData['title'] ?? 'Unknown Title',
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
                  'by ${widget.bookData['author'] ?? 'Unknown Author'}',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoItem(label: 'Genre', value: genre),
                      _VerticalDivider(),
                      _InfoItem(
                        label: 'Year',
                        value: widget.bookData['year-published']?.toString() ?? '-',
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
                  "If you like this book, you may like",
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
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: sameGenreBooks.length,
                          itemBuilder: (context, index) {
                            final book = sameGenreBooks[index];
                            final recImageUrl = book['cover-image-url']?.isNotEmpty == true
                                ? book['cover-image-url']
                                : 'https://via.placeholder.com/80';
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailPage(
                                      bookData: book,
                                      allBooks: widget.allBooks,
                                      processedImage: null,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: recImageUrl,
                                        width: 80,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) {
                                          _logger.e('Failed to load recommended image', error: error);
                                          return Container(
                                            width: 80,
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, size: 40),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        book['title'] ?? 'Unknown',
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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

  Widget _buildCommentSheet() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Comments for ${widget.bookData['title']}',
            style: GoogleFonts.concertOne(fontSize: 18),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Add a comment',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addComment,
            child: const Text('Post Comment'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return ListTile(
                  title: Text(comment['comment']),
                  subtitle: Text('By User ${comment['userId'].substring(0, 6)}...'),
                );
              },
            ),
          ),
        ],
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