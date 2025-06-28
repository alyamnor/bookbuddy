import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_card.dart';
import 'admin_book_detail.dart';

class AdminBookGridByCategory extends StatefulWidget {
  const AdminBookGridByCategory({super.key});

  @override
  State<AdminBookGridByCategory> createState() => _AdminBookGridByCategoryState();
}

class _AdminBookGridByCategoryState extends State<AdminBookGridByCategory> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAllBooks();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.trim();
    });
  }

  Future<void> _saveSearchQuery(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('user-database')
        .doc(user.uid)
        .collection('search_history')
        .add({
      'query': query,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllBooks() async {
    try {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        setState(() => searchQuery = query);
        _saveSearchQuery(query);
      } else {
        setState(() => searchQuery = '');
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }

  Future<String> _determineSearchType(String query) async {
    final lowerQuery = query.toLowerCase();
    const knownGenres = ['romance', 'fantasy', 'self help', 'slice of life', 'horror'];
    
    if (knownGenres.contains(lowerQuery)) {
      return 'genre';
    }

    final authorSnapshot = await FirebaseFirestore.instance
        .collection('book-database')
        .where('author', isEqualTo: query)
        .limit(1)
        .get();
    if (authorSnapshot.docs.isNotEmpty) {
      return 'author';
    }

    return 'title';
  }

  Future<void> _addNewBook() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final publisherController = TextEditingController();
    final yearController = TextEditingController();
    final imageUrlController = TextEditingController();
    final genreController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(70),
                  topRight: Radius.circular(70),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                    'Add New Book',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF987554),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Title',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Author',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: authorController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Publisher',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: publisherController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Year Published',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: yearController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cover Image URL',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Genre',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: genreController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Description',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color(0xFF987554),
                      ),
                    ),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.rubik(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF987554),
                            border: Border.all(
                              color: const Color(0xFF987554),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Add',
                            style: GoogleFonts.rubik(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != true) return;

    try {
      await FirebaseFirestore.instance.collection('book-database').add({
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'publisher': publisherController.text.trim(),
        'year-published': int.tryParse(yearController.text.trim()) ?? 0,
        'cover-image-url': imageUrlController.text.trim(),
        'genre': genreController.text.trim(),
        'description': descriptionController.text.trim(),
      });
      _fetchAllBooks();
    } catch (e) {
      print('Error adding book: $e');
    }
  }

  Widget _buildCategorySection(String category, List<String> bookTitles) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('book-database').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final books = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final genre = (data['genre'] ?? '').toString().toLowerCase();
          final author = (data['author'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          final matchesQuery =
              query.isEmpty || title.contains(query) || genre.contains(query) || author.contains(query);
          final matchesCategory =
              genre == category.toLowerCase() || bookTitles.contains(data['title']);
          return matchesQuery && matchesCategory;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text(
                category.toUpperCase(),
                style: GoogleFonts.concertOne(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF987554),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child: books.isEmpty
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
                      itemBuilder: (context, index) => BookCard(
                        bookData: books[index].data() as Map<String, dynamic>,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminBookDetailPage(
                                bookData: books[index].data() as Map<String, dynamic>,
                                searchType: 'genre',
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
    return FutureBuilder<String>(
      future: _determineSearchType(query),
      builder: (context, searchTypeSnapshot) {
        if (!searchTypeSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final searchType = searchTypeSnapshot.data!;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('book-database').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final lowerQuery = query.toLowerCase();
            final books = snapshot.data!.docs.where((doc) {
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
                        builder: (context) => AdminBookDetailPage(
                          bookData: books[index].data() as Map<String, dynamic>,
                          searchType: searchType,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

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
              decoration: InputDecoration(
                hintText: 'Search by title, author, genre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
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
            child: searchQuery.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewBook,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF987554),
      ),
    );
  }
}

extension ListSort<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    final newList = List<T>.from(this);
    newList.sort(compare);
    return newList;
  }
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}