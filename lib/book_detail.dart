import 'package:flutter/material.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookData;

  const BookDetailPage({super.key, required this.bookData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(bookData['title'] ?? "Book Detail"),
        backgroundColor: const Color(0xFFE5D3B3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookData['cover-image-url'] != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      bookData['cover-image-url'],
                      height: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  bookData['title'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'by ${bookData['author'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Genre: ${bookData['genre'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  bookData['description'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
