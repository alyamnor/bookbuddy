import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_card.dart';
import 'book_detail.dart';

class BookGridByCategory extends StatefulWidget {
  const BookGridByCategory({super.key});

  @override
  State<BookGridByCategory> createState() => _BookGridByCategoryState();
}

class _BookGridByCategoryState extends State<BookGridByCategory> {
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "BookBuddy",
            style: GoogleFonts.concertOne(
              textStyle: const TextStyle(
                fontSize: 30,
                color: Color(0xFF987554),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by title, author, genre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                searchQuery.isEmpty
                    ? ListView(
                      children: [
                        _buildCategorySection('Romance', []),
                        _buildCategorySection('Fantasy', []),
                        _buildCategorySection('Self Help', []),
                        _buildCategorySection('Slice of Life', []),
                        _buildCategorySection('Horror', []),
                      ],
                    )
                    : _buildSearchResults(searchQuery),
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
              final title = (data['title'] ?? '').toString().toLowerCase();
              final genre = (data['genre'] ?? '').toString().toLowerCase();
              final author = (data['author'] ?? '').toString().toLowerCase();
              final query = searchQuery.toLowerCase();

              final matchesQuery =
                  title.contains(query) ||
                  genre.contains(query) ||
                  author.contains(query);

              final matchesCategory =
                  genre == category.toLowerCase() ||
                  bookTitles.contains(data['title']);

              return matchesQuery && matchesCategory;
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
                style: GoogleFonts.concertOne(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF987554), // Deep purple color
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child:
                  books.isEmpty
                      ? Center(
                        child: Text(
                          'No results found in $category.',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: books.length,
                        itemBuilder:
                            (context, index) => BookCard(
                              bookData:
                                  books[index].data() as Map<String, dynamic>,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(thickness: 1),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(String query) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('book-database').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final lowerQuery = query.toLowerCase();
        final books =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              final genre = (data['genre'] ?? '').toString().toLowerCase();
              final author = (data['author'] ?? '').toString().toLowerCase();

              return title.contains(lowerQuery) ||
                  genre.contains(lowerQuery) ||
                  author.contains(lowerQuery);
            }).toList();

        if (books.isEmpty) {
          return const Center(
            child: Text(
              'No books found.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return BookCard(
              bookData: books[index].data() as Map<String, dynamic>,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BookDetailPage(
                          bookData: books[index].data() as Map<String, dynamic>,
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
