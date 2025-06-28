import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AdminBookDetailPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final File? processedImage;
  final String searchType;

  const AdminBookDetailPage({
    super.key,
    required this.bookData,
    this.processedImage,
    required this.searchType,
  });

  @override
  State<AdminBookDetailPage> createState() => _AdminBookDetailPageState();
}

class _AdminBookDetailPageState extends State<AdminBookDetailPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  bool _showProcessedImage = false;
  List<Map<String, dynamic>> _comments = [];
  double _userRating = 0;
  String? _bookId;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeBookId();
    _fetchComments();
    _fetchUserRating();
  }

  Future<void> _initializeBookId() async {
    if (widget.bookData['id'] != null) {
      setState(() => _bookId = widget.bookData['id']);
    } else {
      final bookRef = await FirebaseFirestore.instance
          .collection('book-database')
          .where('title', isEqualTo: widget.bookData['title'])
          .limit(1)
          .get();
      if (bookRef.docs.isNotEmpty) {
        setState(() => _bookId = bookRef.docs.first.id);
      }
    }
  }

  Future<void> _deleteBook() async {
    if (_bookId == null) {
      Fluttertoast.showToast(msg: 'Book ID not found');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Confirm Deletion',
          style: GoogleFonts.rubik(
            color: const Color(0xFF987554),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${widget.bookData['title']} from the database?',
          style: GoogleFonts.roboto(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.rubik(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('book-database').doc(_bookId).delete();
      _logger.i('Book deleted: ${widget.bookData['title']}');
      Fluttertoast.showToast(msg: 'Book deleted successfully');
      Navigator.pop(context);
    } catch (e) {
      _logger.e('Delete book error', error: e);
      Fluttertoast.showToast(msg: 'Failed to delete book');
    }
  }

  Future<void> _fetchComments() async {
    if (_bookId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('book-database')
        .doc(_bookId)
        .collection('book-comments')
        .doc('book-review')
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _comments = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Confirm Deletion',
          style: GoogleFonts.rubik(
            color: const Color(0xFF987554),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: GoogleFonts.roboto(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.rubik(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('book-database')
          .doc(_bookId)
          .collection('book-comments')
          .doc('book-review')
          .collection('comments')
          .doc(commentId)
          .delete();
      _logger.i('Comment deleted for ${widget.bookData['title']}');
      await _fetchComments();
      Fluttertoast.showToast(msg: 'Comment deleted');
    } catch (e) {
      _logger.e('Delete comment error', error: e);
      Fluttertoast.showToast(msg: 'Failed to delete comment');
    }
  }

  Future<void> _fetchUserRating() async {
    if (userId == null || _bookId == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('user-database')
        .doc(userId)
        .collection('ratings')
        .doc(_bookId)
        .get();
    if (doc.exists) {
      setState(() {
        _userRating = (doc.data()?['rating'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _updateRating(double rating) async {
    if (userId == null || _bookId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('user-database')
          .doc(userId)
          .collection('ratings')
          .doc(_bookId)
          .set({
        'rating': rating.toInt(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _userRating = rating;
      });
      Fluttertoast.showToast(msg: 'Rating submitted');
    } catch (e) {
      _logger.e('Rating error', error: e);
      Fluttertoast.showToast(msg: 'Failed to submit rating');
    }
  }

  Future<void> _editBook() async {
    final titleController = TextEditingController(text: widget.bookData['title'] ?? '');
    final authorController = TextEditingController(text: widget.bookData['author'] ?? '');
    final publisherController = TextEditingController(text: widget.bookData['publisher'] ?? '');
    final yearController = TextEditingController(text: widget.bookData['year-published']?.toString() ?? '');
    final genreController = TextEditingController(text: widget.bookData['genre'] ?? '');
    final descriptionController = TextEditingController(text: widget.bookData['description'] ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => SingleChildScrollView(
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
                'Edit Book Details',
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
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                  'Publisher',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF987554),
                  ),
                ),
              ),
              TextField(
                controller: publisherController,
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.roboto(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                  'Year Published',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF987554),
                  ),
                ),
              ),
              TextField(
                controller: yearController,
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.roboto(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Genre',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF987554),
                  ),
                ),
              ),
              TextField(
                controller: genreController,
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.roboto(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
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
                  'Description',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF987554),
                  ),
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.roboto(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    onPressed: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF987554),
                        border: Border.all(color: const Color(0xFF987554)),
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
      ),
    );

    if (result != true || _bookId == null) return;

    try {
      await FirebaseFirestore.instance.collection('book-database').doc(_bookId).update({
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'publisher': publisherController.text.trim(),
        'year-published': int.tryParse(yearController.text.trim()) ?? 0,
        'genre': genreController.text.trim(),
        'description': descriptionController.text.trim(),
        'cover-image-url': widget.bookData['cover-image-url'],
      });
      _logger.i('Book updated: ${titleController.text}');
      Fluttertoast.showToast(msg: 'Book updated successfully');
      setState(() {
        widget.bookData['title'] = titleController.text.trim();
        widget.bookData['author'] = authorController.text.trim();
        widget.bookData['publisher'] = publisherController.text.trim();
        widget.bookData['year-published'] = int.tryParse(yearController.text.trim()) ?? 0;
        widget.bookData['genre'] = genreController.text.trim();
        widget.bookData['description'] = descriptionController.text.trim();
      });
    } catch (e) {
      _logger.e('Update book error', error: e);
      Fluttertoast.showToast(msg: 'Failed to update book');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.bookData['cover-image-url']?.isNotEmpty == true
        ? widget.bookData['cover-image-url']
        : 'https://via.placeholder.com/150';
    final genre = widget.bookData['genre'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
              size: 30,
            ),
            onPressed: _deleteBook,
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 30),
            onPressed: _editBook,
          ),
          IconButton(
            icon: const Icon(Icons.comment_outlined, size: 30),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black54,
                elevation: 0,
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
              const SizedBox(height: 10),
              Center(
                child: RatingBar.builder(
                  initialRating: _userRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 30,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Color(0xFF987554),
                  ),
                  onRatingUpdate: _updateRating,
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
        ),
      ),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16,
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
            'Community Reviews',
            style: GoogleFonts.rubik(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF987554),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _comments.isEmpty
                ? const Center(
                    child: Text(
                      'No comments yet.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _comments.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                comment['preferredName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteComment(comment['id']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment['comment']),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
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