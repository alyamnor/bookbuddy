import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add New Book', style: GoogleFonts.concertOne(fontSize: 18)),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: publisherController,
                decoration: const InputDecoration(labelText: 'Publisher', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: yearController,
                decoration: const InputDecoration(labelText: 'Year Published', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Cover Image URL', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: genreController,
                decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildRecommendedSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Stream.fromFuture(Future.wait([
        FirebaseFirestore.instance
            .collection('user-database')
            .doc(user.uid)
            .collection('bookmarks')
            .get(),
        FirebaseFirestore.instance
            .collection('user-database')
            .doc(user.uid)
            .collection('book-shelf')
            .get(),
        FirebaseFirestore.instance
            .collection('user-database')
            .doc(user.uid)
            .collection('search_history')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .get(),
        FirebaseFirestore.instance.collection('book-database').get(),
        FirebaseFirestore.instance.collectionGroup('ratings').get(),
      ])),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bookmarksSnapshot = snapshot.data![0];
        final bookshelfSnapshot = snapshot.data![1];
        final searchHistorySnapshot = snapshot.data![2];
        final booksSnapshot = snapshot.data![3];
        final ratingsSnapshot = snapshot.data![4];

        final genres = <String>{};
        final authors = <String>{};
        final userBookIds = <String>{};

        for (var doc in bookmarksSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['genre'] != null) genres.add(data['genre'].toString().toLowerCase());
          if (data['author'] != null) authors.add(data['author'].toString().toLowerCase());
          userBookIds.add(doc.id);
        }

        for (var doc in bookshelfSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['genre'] != null) genres.add(data['genre'].toString().toLowerCase());
          if (data['author'] != null) authors.add(data['author'].toString().toLowerCase());
          userBookIds.add(doc.id);
        }

        for (var doc in searchHistorySnapshot.docs) {
          final query = (doc['query'] ?? '').toString().toLowerCase();
          if (['romance', 'fantasy', 'self help', 'slice of life', 'horror'].contains(query)) {
            genres.add(query);
          } else {
            authors.add(query);
          }
        }

        final contentBooks = booksSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final genre = (data['genre'] ?? '').toString().toLowerCase();
          final author = (data['author'] ?? '').toString().toLowerCase();
          return (genres.contains(genre) || authors.contains(author)) && !userBookIds.contains(doc.id);
        }).map((doc) => {'id': doc.id, 'data': doc.data() as Map<String, dynamic>, 'score': 1.0}).toList();

        final userSimilarities = <String, double>{};
        final currentUserRatings = ratingsSnapshot.docs
            .where((doc) => doc.reference.parent.parent!.id == user.uid)
            .map((doc) => {'id': doc.id, 'rating': doc['rating']})
            .toList();

        final otherUsersRatings = <String, Map<String, int>>{};
        for (var doc in ratingsSnapshot.docs) {
          final otherUserId = doc.reference.parent.parent!.id;
          if (otherUserId == user.uid) continue;
          otherUsersRatings.putIfAbsent(otherUserId, () => {})[doc.id] = doc['rating'];
        }

        for (var entry in otherUsersRatings.entries) {
          final otherUserId = entry.key;
          final otherRatings = entry.value;
          double dotProduct = 0;
          double normA = 0;
          double normB = 0;
          for (var userRating in currentUserRatings) {
            final bookId = userRating['id'];
            final a = userRating['rating'].toDouble();
            final b = (otherRatings[bookId] ?? 0).toDouble();
            dotProduct += a * b;
            normA += a * a;
            normB += b * b;
          }
          final similarity = normA > 0 && normB > 0 ? dotProduct / (sqrt(normA) * sqrt(normB)) : 0;
          if (similarity > 0) userSimilarities[otherUserId] = similarity.toDouble();
        }

        final similarUsers = userSimilarities.entries
            .toList()
            .sorted((a, b) => b.value.compareTo(a.value))
            .take(5)
            .map((e) => e.key)
            .toList();

        final collabBooks = ratingsSnapshot.docs
            .where((doc) => similarUsers.contains(doc.reference.parent.parent!.id))
            .where((doc) => (doc['rating'] ?? 0) >= 4)
            .where((doc) => !userBookIds.contains(doc.id))
            .map((doc) {
              final book = booksSnapshot.docs.firstWhereOrNull((b) => b.id == doc.id);
              if (book == null) return null;
              return {
                'id': doc.id,
                'data': book.data() as Map<String, dynamic>,
                'score': (doc['rating'] ?? 0).toDouble() / 5.0
              };
            }).whereType<Map<String, dynamic>>().toList();

        final allRecommendations = [];
        allRecommendations.addAll(contentBooks.map((b) => {
          ...b,
          'score': ((b['score'] ?? 0) as double) * 0.75
        }));
        allRecommendations.addAll(collabBooks.map((b) => {...b, 'score': b['score'] * 0.25}));

        final bookMap = <String, Map<String, dynamic>>{};
        for (var rec in allRecommendations) {
          final id = rec['id'];
          if (bookMap.containsKey(id)) {
            bookMap[id]!['score'] = (bookMap[id]!['score'] as double) + (rec['score'] as double);
          } else {
            bookMap[id] = rec;
          }
        }
        final recommendedBooks = bookMap.values.toList()
          ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

        // Only take the top 5 recommendations
        final topRecommendations = recommendedBooks.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text(
                'RECOMMENDED',
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
              child: topRecommendations.isEmpty
                  ? Center(
                      child: Text(
                        'No recommendations available.',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topRecommendations.length,
                      itemBuilder: (context, index) {
                        final book = topRecommendations[index];
                        return BookCard(
                          bookData: book['data'] as Map<String, dynamic>,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminBookDetailPage(
                                  bookData: book['data'] as Map<String, dynamic>,
                                  searchType: 'recommended',
                                ),
                              ),
                            );
                          },
                        );
                      },
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
                      _buildRecommendedSection(),
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
        child: const Icon(Icons.add),
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