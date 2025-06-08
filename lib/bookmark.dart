import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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

  Future<void> _updateRating(String bookId, int rating) async {
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('user-database')
          .doc(userId)
          .collection('ratings')
          .doc(bookId)
          .set({
            'rating': rating,
            'timestamp': FieldValue.serverTimestamp(),
          });
      Fluttertoast.showToast(msg: 'Rating updated');
      _fetchBookmarks();
    } catch (e) {
      _logger.e('Error updating rating', error: e);
      Fluttertoast.showToast(msg: 'Failed to update rating');
    }
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Bookmark',
          style: GoogleFonts.concertOne(fontSize: 20, color: const Color(0xFF987554)),
        ),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: bookmarks.isEmpty
            ? const Center(child: Text('No bookmarks yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final book = bookmarks[index];
                  final bookId = book['bookId'] ?? book['title']; // Fallback to title
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: book['cover-image-url'] ?? 'https://via.placeholder.com/80',
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) {
                          _logger.e('Failed to load bookmark image', error: error);
                          return const Icon(Icons.broken_image, size: 50);
                        },
                      ),
                      title: Text(
                        book['title'] ?? 'Unknown Title',
                        style: GoogleFonts.concertOne(
                          fontSize: 18,
                          color: const Color(0xFF987554),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'by ${book['author'] ?? 'Unknown Author'}',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          RatingBar.builder(
                            initialRating: (book['rating'] ?? 0).toDouble(),
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemSize: 20,
                            itemBuilder: (context, _) => const Icon(
                              Icons.star,
                              color: Color(0xFF987554),
                            ),
                            onRatingUpdate: (rating) {
                              _updateRating(bookId, rating.toInt());
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailPage(
                              bookData: book,
                              allBooks: [],
                              processedImage: null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                  },
                ),
          ),
        );
      }
    }