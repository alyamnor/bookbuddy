import 'package:bookbuddy/book_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';


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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5D3B3),
        foregroundColor: Colors.white,
        elevation: 0,
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
        centerTitle: true,
      ),
        bottomNavigationBar: CurvedNavigationBar(
    backgroundColor: Colors.transparent,
    color: const Color(0xFFE5D3B3),
    items: <Widget>[
      Icon(Icons.home_filled, size: 30, color: Color(0xFF987554),),
      Icon(Icons.add_a_photo_sharp, size: 30, color: Color(0xFF987554)),
      Icon(Icons.person_2, size: 30, color: Color(0xFF987554)),
    ],
    onTap: (index) {
      //Handle button tap
    },
  ),
  body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by title, author, genre',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Genre Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children:
                    genres.map((genre) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(genre),
                          selected: selectedGenre == genre,
                          onSelected: (isSelected) {
                            setState(() {
                              selectedGenre = genre;
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // Book List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('book-database')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, List<DocumentSnapshot>> categoryMap = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? '';

                    final title = data['title']?.toString().toLowerCase() ?? '';
                    final author =
                        data['author']?.toString().toLowerCase() ?? '';
                    final genre = data['genre']?.toString().toLowerCase() ?? '';

                    bool matchesSearch =
                        title.contains(searchQuery) ||
                        author.contains(searchQuery) ||
                        genre.contains(searchQuery);

                    bool matchesGenre =
                        selectedGenre == 'All' ||
                        genre == selectedGenre.toLowerCase();

                    if (matchesSearch && matchesGenre) {
                      categoryMap.putIfAbsent(category, () => []).add(doc);
                    }
                  }

                  if (categoryMap.isEmpty) {
                    return const Center(child: Text("No books found."));
                  }

                  return ListView(
                    children:
                        categoryMap.entries.map((entry) {
                          final category = entry.key;
                          final books = entry.value;

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
                                  itemBuilder: (context, index) {
                                    final book =
                                        books[index].data()
                                            as Map<String, dynamic>;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => BookDetailPage(
                                                  bookData: book,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                book['cover-image-url'] ?? '',
                                                height: 150,
                                                width: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                      Icons.broken_image,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              book['title'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

