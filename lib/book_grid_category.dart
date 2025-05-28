//book_grid_category.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_card.dart';
import 'search_bar.dart';
import 'book_detail.dart';

class BookGridByCategory extends StatefulWidget {
  const BookGridByCategory({super.key});

  @override
  State<BookGridByCategory> createState() => _BookGridByCategoryState();
}

class _BookGridByCategoryState extends State<BookGridByCategory> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BookBuddy",
          style: GoogleFonts.concertOne(
            textStyle: const TextStyle(
              fontSize: 25,
              color: Color(0xFF987554),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          BookSearchBar(onChanged: (val) => setState(() => searchQuery = val)),
          Expanded(
            child: ListView(
              children: [
                _buildCategorySection('Romance', [
                  'Only You',
                  'Voice of You',
                  'Soft Romance',
                  'Bayani',
                ]),
                _buildCategorySection('Fantasy', [
                  'Jika Aku',
                  'Kolomi',
                  'Terang Di',
                  'Anika',
                ]),
                _buildCategorySection('Self Help', [
                  'Journey',
                  'Self Love',
                  'Clarity',
                  'Rise',
                ]),
                _buildCategorySection('Slice of Life', [
                  'Flying Kite',
                  'After Chrome',
                  'Tumbling',
                  'Keiko',
                ]),
                _buildCategorySection(
                  'Horror',
                  [],
                ), // Empty for now, can be populated later
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, List<String> bookTitles) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('book-database').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final books =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title']?.toLowerCase() ?? '';
              final genre = data['genre']?.toLowerCase() ?? '';
              return (title.contains(searchQuery) ||
                      genre.contains(searchQuery)) &&
                  (genre == category.toLowerCase() ||
                      bookTitles.contains(data['title']));
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder:
                    (context, index) => BookCard(
                      bookData: books[index].data() as Map<String, dynamic>,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => BookDetailPage(
                                  bookData:
                                      books[index].data()
                                          as Map<String, dynamic>,
                                ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
