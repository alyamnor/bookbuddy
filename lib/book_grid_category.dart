import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_card.dart';
import 'search_bar.dart'; // Ensure this file defines AppSearchBar or change to the correct widget name
import 'genre_chips.dart';
import 'book_detail.dart';

class BookGridByCategory extends StatefulWidget {
  const BookGridByCategory({super.key});

  @override
  State<BookGridByCategory> createState() => _BookGridByCategoryState();
}

class _BookGridByCategoryState extends State<BookGridByCategory> {
  String searchQuery = '';
  String selectedGenre = 'All';
  final genres = ['All', 'Romance', 'Horror', 'Self Help', 'Slice of Life'];

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
          GenreChipList(
            genres: genres,
            selectedGenre: selectedGenre,
            onSelected: (genre) => setState(() => selectedGenre = genre),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('book-database').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final filteredBooks = _filterBooks(snapshot.data!.docs);

                if (filteredBooks.isEmpty) {
                  return const Center(child: Text("No books found."));
                }

                return ListView(
                  children: filteredBooks.entries.map((entry) => _buildCategorySection(entry.key, entry.value)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<DocumentSnapshot>> _filterBooks(List<DocumentSnapshot> docs) {
    final map = <String, List<DocumentSnapshot>>{};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['title']?.toLowerCase() ?? '';
      final author = data['author']?.toLowerCase() ?? '';
      final genre = data['genre']?.toLowerCase() ?? '';
      final category = data['category'] ?? '';

      if ((title.contains(searchQuery) || author.contains(searchQuery) || genre.contains(searchQuery)) &&
          (selectedGenre == 'All' || genre == selectedGenre.toLowerCase())) {
        map.putIfAbsent(category, () => []).add(doc);
      }
    }
    return map;
  }

  Widget _buildCategorySection(String category, List<DocumentSnapshot> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Text(category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) => BookCard(
              bookData: books[index].data() as Map<String, dynamic>,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailPage(bookData: books[index].data() as Map<String, dynamic>),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
