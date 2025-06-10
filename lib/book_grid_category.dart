import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
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
  List<Map<String, dynamic>> _allBooks = []; // Cache for full book database

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAllBooks(); // Fetch full book list on init
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllBooks() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('book-database').get();
      setState(() {
        _allBooks = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      });
    } catch (e) {
      print('Error fetching all books: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() => searchQuery = query);
      _saveSearchQuery(query);
    } else {
      setState(() => searchQuery = '');
    }
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

  Future<String> _determineSearchType(String query) async {
    final lowerQuery = query.toLowerCase();
    // List of known genres
    const knownGenres = ['romance', 'fantasy', 'self help', 'slice of life', 'horror'];
    
    // Check if query matches a genre
    if (knownGenres.contains(lowerQuery)) {
      return 'genre';
    }

    // Check if query matches an author
    final authorSnapshot = await FirebaseFirestore.instance
        .collection('book-database')
        .where('author', isEqualTo: query)
        .limit(1)
        .get();
    if (authorSnapshot.docs.isNotEmpty) {
      return 'author';
    }

    // Default to title search
    return 'title';
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

        // Collect user preferences for content-based filtering
        final genres = <String>{};
        final authors = <String>{};
        final userBookIds = <String>{};

        // From bookmarks
        for (var doc in bookmarksSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['genre'] != null) genres.add(data['genre'].toString().toLowerCase());
          if (data['author'] != null) authors.add(data['author'].toString().toLowerCase());
          userBookIds.add(doc.id);
        }

        // From bookshelf
        for (var doc in bookshelfSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['genre'] != null) genres.add(data['genre'].toString().toLowerCase());
          if (data['author'] != null) authors.add(data['author'].toString().toLowerCase());
          userBookIds.add(doc.id);
        }

        // From search history
        for (var doc in searchHistorySnapshot.docs) {
          final query = (doc['query'] ?? '').toString().toLowerCase();
          if (['romance', 'fantasy', 'self help', 'slice of life', 'horror'].contains(query)) {
            genres.add(query);
          } else {
            authors.add(query);
          }
        }

        // Content-based recommendations
        final contentBooks = booksSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final genre = (data['genre'] ?? '').toString().toLowerCase();
          final author = (data['author'] ?? '').toString().toLowerCase();
          return (genres.contains(genre) || authors.contains(author)) && !userBookIds.contains(doc.id);
        }).map((doc) => {'id': doc.id, 'data': doc.data() as Map<String, dynamic>, 'score': 1.0}).toList();

        // Collaborative filtering: Find similar users based on ratings
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

        // Compute cosine similarity
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

        // Get top 5 similar users
        final similarUsers = userSimilarities.entries
            .toList()
            .sorted((a, b) => b.value.compareTo(a.value))
            .take(5)
            .map((e) => e.key)
            .toList();

        // Collaborative recommendations
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

        // Combine recommendations
        final allRecommendations = [];
        allRecommendations.addAll(contentBooks.map((b) => {
          ...b,
          'score': ((b['score'] ?? 0) as double) * 0.75
        }));
        allRecommendations.addAll(collabBooks.map((b) => {...b, 'score': b['score'] * 0.25}));

        // Sort and deduplicate
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
          ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double))
          ..take(5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Text(
                'RECOMMENDED FOR YOU',
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
              child: recommendedBooks.isEmpty
                  ? const Center(
                      child: Text(
                        'No recommendations available.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedBooks.length,
                      itemBuilder: (context, index) => BookCard(
                        bookData: recommendedBooks[index]['data'],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailPage(
                                bookData: recommendedBooks[index]['data'],
                                allBooks: _allBooks, // Use full book database
                                searchType: 'genre', // Use genre for recommendations
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
                              builder: (context) => BookDetailPage(
                                bookData: books[index].data() as Map<String, dynamic>,
                                allBooks: _allBooks, // Use full book database
                                searchType: 'genre', // Use genre for category
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
                        builder: (context) => BookDetailPage(
                          bookData: books[index].data() as Map<String, dynamic>,
                          allBooks: _allBooks, // Use full book database
                          searchType: searchType, // Dynamic search type
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
}

// Extension to support sorting
extension ListSort<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    final newList = List<T>.from(this);
    newList.sort(compare);
    return newList;
  }
}

// Extension to support firstWhereOrNull
extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}