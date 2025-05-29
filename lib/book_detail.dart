import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookData;
  final List<Map<String, dynamic>> allBooks;
  // Declare logger as a class-level variable
  final Logger _logger = Logger(
    printer: PrettyPrinter(),
    filter: null, // Use null for debug mode; replace with ProductionFilter() for production
  );

  BookDetailPage({
    super.key,
    required this.bookData,
    required this.allBooks,
  });

  @override
  Widget build(BuildContext context) {
    // Log bookData and allBooks for debugging
    _logger.d('bookData: $bookData');
    _logger.d('allBooks length: ${allBooks.length}');

    final imageUrl = bookData['cover-image-url']?.isNotEmpty == true
        ? bookData['cover-image-url']
        : 'https://via.placeholder.com/150';
    final genre = bookData['genre'];
    final sameGenreBooks = allBooks
        .where((book) =>
            book['genre'] == genre &&
            book['title'] != bookData['title'])
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.bookmark_border_outlined, size: 30),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, size: 30),
                  onPressed: () {},
                ),
              ],
            ),
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
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4), // Shadow below the image
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
                        _logger.e('Failed to load cover image: $imageUrl', error: error, stackTrace: stackTrace);
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  bookData['title'] ?? '',
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
                  'by ${bookData['author'] ?? 'Unknown'}',
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
                      _InfoItem(label: 'Genre', value: bookData['genre'] ?? '-'),
                      _VerticalDivider(),
                      _InfoItem(
                        label: 'Year',
                        value: bookData['year-published']?.toString() ?? '-',
                      ),
                      _VerticalDivider(),
                      _InfoItem(label: 'Publisher', value: bookData['publisher'] ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (bookData['description'] != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    bookData['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade400, thickness: 1),
                const SizedBox(height: 10),
                Text(
                  "You may like",
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
                                      allBooks: allBooks,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    recImageUrl,
                                    width: 80,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      _logger.e('Failed to load recommended book image: $recImageUrl', error: error, stackTrace: stackTrace);
                                      return Container(
                                        width: 80,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image, size: 40),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
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