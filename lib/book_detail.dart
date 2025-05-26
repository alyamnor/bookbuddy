import 'package:flutter/material.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookData;

  const BookDetailPage({super.key, required this.bookData});

  @override
  Widget build(BuildContext context) {
    // OCR extracted values
    final String ocrText = (bookData['ocr_text'] ?? '').toLowerCase();
    final String title = (bookData['ground_truth_title'] ?? '').toLowerCase();
    final String author = (bookData['ground_truth_author'] ?? '').toLowerCase();

    final bool titleMatch = ocrText.contains(title);
    final bool authorMatch = ocrText.contains(author);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(bookData['ground_truth_title'] ?? "Book Detail"),
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
                  bookData['ground_truth_title'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'by ${bookData['ground_truth_author'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'OCR Extracted:',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ocrText.trim().isEmpty ? 'No OCR data found.' : ocrText,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ),
              Text.rich(
                TextSpan(
                  text: 'Match Results:\n',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '• Title match: ',
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    TextSpan(
                      text: titleMatch ? '✅' : '❌',
                      style: TextStyle(color: titleMatch ? Colors.green : Colors.red),
                    ),
                    const TextSpan(text: '\n• Author match: '),
                    TextSpan(
                      text: authorMatch ? '✅' : '❌',
                      style: TextStyle(color: authorMatch ? Colors.green : Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (bookData['genre'] != null)
                Text('Genre: ${bookData['genre']}', style: const TextStyle(fontSize: 14)),
              if (bookData['description'] != null) ...[
                const SizedBox(height: 10),
                Text(
                  bookData['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
