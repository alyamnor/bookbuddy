//book_card.dart
import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> bookData;
  final VoidCallback onTap;

  const BookCard({super.key, required this.bookData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = bookData['cover-image-url']?.isNotEmpty == true
        ? bookData['cover-image-url']
        : 'https://via.placeholder.com/150';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                height: 150,
                width: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 100);
                },
              ),
            ),
            const SizedBox(height: 5),
            Text(
              bookData['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}