import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BookDetailPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final List<Map<String, dynamic>> allBooks;
  final File? processedImage;
  final String searchType; // 'title', 'author', or 'genre'

  const BookDetailPage({
    super.key,
    required this.bookData,
    required this.allBooks,
    this.processedImage,
    required this.searchType,
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
  double _userRating = 0;
  String? _bookId;

  @override
  void initState() {
    super.initState();
    _initializeBookId();
    _checkBookmarkStatus();
    _fetchComments();
    _fetchUserRating();
  }

  Future<void> _initializeBookId() async {
    if (widget.bookData['id'] != null) {
      setState(() => _bookId = widget.bookData['id']);
    } else {
      final bookRef =
          await FirebaseFirestore.instance
              .collection('book-database')
              .where('title', isEqualTo: widget.bookData['title'])
              .limit(1)
              .get();
      if (bookRef.docs.isNotEmpty) {
        setState(() => _bookId = bookRef.docs.first.id);
      }
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (userId == null || _bookId == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('user-database')
            .doc(userId)
            .collection('bookmarks')
            .doc(_bookId)
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
    if (_bookId == null) {
      Fluttertoast.showToast(msg: 'Book ID not found');
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection('user-database')
        .doc(userId)
        .collection('bookmarks')
        .doc(_bookId);

    try {
      if (_isBookmarked) {
        await docRef.delete();
        _logger.i('Bookmark removed: ${widget.bookData['title']}');
        Fluttertoast.showToast(msg: 'Bookmark removed');
      } else {
        await docRef.set({
          'bookId': _bookId,
          'title': widget.bookData['title'],
          'author': widget.bookData['author'],
          'cover-image-url': widget.bookData['cover-image-url'],
          'genre': widget.bookData['genre'] ?? '',
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
    if (_bookId == null) return;
    final snapshot =
        await FirebaseFirestore.instance
            .collection('book-database')
            .doc(_bookId)
            .collection('book-comments')
            .doc('book-review')
            .collection('comments')
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      _comments = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _addComment() async {
    if (userId == null ||
        _commentController.text.trim().isEmpty ||
        _bookId == null)
      return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('user-database')
              .doc(userId)
              .get();
      final preferredName = userDoc.data()?['preferredName'] ?? 'Anonymous';
      final commentText = _commentController.text.trim();

      final commentData = {
        'userId': userId,
        'comment': commentText,
        'preferredName': preferredName,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save comment under the book
      await FirebaseFirestore.instance
          .collection('book-database')
          .doc(_bookId)
          .collection('book-comments')
          .doc('book-review')
          .collection('comments')
          .add(commentData);

      // Save comment under user profile
      await FirebaseFirestore.instance
          .collection('user-database')
          .doc(userId)
          .collection('comments')
          .add({
            'bookId': _bookId,
            'comment': commentText,
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

  Future<void> _fetchUserRating() async {
    if (userId == null || _bookId == null) return;
    final doc =
        await FirebaseFirestore.instance
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

  List<Map<String, dynamic>> _getRecommendedBooks() {
    _logger.i('Recommendation searchType: ${widget.searchType}');
    final currentBookId = widget.bookData['id'];
    final currentTitle = widget.bookData['title']?.toLowerCase() ?? '';
    final currentGenre = widget.bookData['genre']?.toLowerCase() ?? '';
    final currentAuthor = widget.bookData['author']?.toLowerCase() ?? '';

    List<Map<String, dynamic>> filteredBooks =
        widget.allBooks.where((book) {
          final isSameBook =
              book['id'] == currentBookId ||
              (book['title']?.toLowerCase() ?? '') == currentTitle;
          if (isSameBook) return false;

          switch (widget.searchType) {
            case 'title':
              return (book['genre']?.toLowerCase() ?? '') == currentGenre ||
                  (book['author']?.toLowerCase() ?? '') == currentAuthor;
            case 'author':
              return (book['genre']?.toLowerCase() ?? '') == currentGenre ||
                  (book['author']?.toLowerCase() ?? '') == currentAuthor;
            case 'genre':
            default:
              return (book['genre']?.toLowerCase() ?? '') == currentGenre;
          }
        }).toList();

    if (widget.searchType == 'author') {
      filteredBooks.sort((a, b) {
        final aAuthorMatch =
            (a['author']?.toLowerCase() ?? '') == currentAuthor ? 1 : 0;
        final bAuthorMatch =
            (b['author']?.toLowerCase() ?? '') == currentAuthor ? 1 : 0;
        if (bAuthorMatch != aAuthorMatch) {
          return bAuthorMatch - aAuthorMatch;
        }
        // Secondary sort by year-published (newer first)
        final aYear = a['year-published'] ?? 0;
        final bYear = b['year-published'] ?? 0;
        return bYear.compareTo(aYear);
      });
    }

    return filteredBooks.take(20).toList(); // Limit to 5 recommendations
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        widget.bookData['cover-image-url']?.isNotEmpty == true
            ? widget.bookData['cover-image-url']
            : 'https://via.placeholder.com/150';
    final genre = widget.bookData['genre'] ?? 'Unknown';
    final recommendedBooks = _getRecommendedBooks();

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
  backgroundColor: Colors.transparent, // Make the default background transparent
  barrierColor: Colors.black54, // Adjust barrier color (semi-transparent black)
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
                    child:
                        _showProcessedImage && widget.processedImage != null
                            ? Image.file(
                              widget.processedImage!,
                              height: 300,
                              fit: BoxFit.cover,
                            )
                            : CachedNetworkImage(
                              imageUrl: imageUrl,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget: (context, url, error) {
                                _logger.e(
                                  'Failed to load cover image',
                                  error: error,
                                );
                                return const Icon(
                                  Icons.broken_image,
                                  size: 100,
                                );
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
                  itemBuilder:
                      (context, _) =>
                          const Icon(Icons.star, color: Color(0xFF987554)),
                  onRatingUpdate: _updateRating,
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
                      _InfoItem(label: 'Genre', value: genre),
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
                  "If you like this book, you may like",
                  style: GoogleFonts.rubik(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF987554),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                recommendedBooks.isNotEmpty
                    ? SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendedBooks.length,
                        itemBuilder: (context, index) {
                          final book = recommendedBooks[index];
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
                                        processedImage: null,
                                        searchType: widget.searchType,
                                      ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: recImageUrl,
                                      width: 80,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget: (context, url, error) {
                                        _logger.e(
                                          'Failed to load recommended image',
                                          error: error,
                                        );
                                        return Container(
                                          width: 80,
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                          ),
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
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
            child:
                _comments.isEmpty
          ? const Center(
              child: Text(
                'No comments yet.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 14, // Increased font size
                ),
              ),
            )
                    : ListView.separated(
                      itemCount: _comments.length,
                      separatorBuilder:
                          (context, index) =>
                              Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['preferredName'] ?? 'Anonymous',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(comment['comment']),
                          ],
                        );
                      },
                    ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade400),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Share your reviews...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF987554)),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Move these classes outside of _BookDetailPageState

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
