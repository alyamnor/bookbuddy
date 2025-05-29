import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_detail.dart';

class MyImagePicker extends StatefulWidget {
  const MyImagePicker({super.key});

  @override
  State<MyImagePicker> createState() => _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  File? _image;
  String result = '';
  bool _isLoading = false;
  Map<String, dynamic>? _bookData;
  final logger = Logger();

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      result = '';
      _bookData = null;
      _isLoading = true;
    });

    final inputImage = InputImage.fromFilePath(_image!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      final scannedText = recognizedText.text.toLowerCase();
      logger.i("OCR Result: $scannedText");

      await _searchBook(scannedText);
    } catch (e, stackTrace) {
      logger.e("OCR Error", error: e, stackTrace: stackTrace);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Failed to process image text. Try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      await textRecognizer.close();
    }
  }

  Future<void> _searchBook(String text) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('book-database').get();

      List<Map<String, dynamic>> potentialMatches = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String?)?.toLowerCase() ?? '';
        final author = (data['author'] as String?)?.toLowerCase() ?? '';

        final textLines = text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.length > 3)
            .toList();
        bool wordMatch = title
            .split(' ')
            .where((word) => word.length > 3)
            .any((word) => textLines.any((line) => line.contains(word)));

        double titleScore = StringSimilarity.compareTwoStrings(text, title);
        double authorScore = StringSimilarity.compareTwoStrings(text, author);

        bool authorMatch = text.contains(author) || authorScore > 0.5;
        bool fuzzyTitleMatch = titleScore > 0.5;

        logger.i("Checking book: $title by $author");
        logger.i(
          "Title score: $titleScore | Author score: $authorScore | WordMatch: $wordMatch",
        );

        double combinedScore = (titleScore * 0.7) + (authorScore * 0.3);

        if (wordMatch || (authorMatch && fuzzyTitleMatch)) {
          potentialMatches.add({
            'data': data,
            'score': combinedScore,
            'titleScore': titleScore,
            'authorScore': authorScore,
            'wordMatch': wordMatch,
          });
        }
      }

      if (potentialMatches.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("No Match Found"),
            content: const Text(
              "Try scanning again or selecting a clearer image.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      potentialMatches.sort((a, b) => b['score'].compareTo(a['score']));
      final bestMatch = potentialMatches.first;

      logger.i(
        "BEST MATCH: ${bestMatch['data']['title']} with score: ${bestMatch['score']}",
      );

      if (!mounted) return;
      setState(() {
        _bookData = bestMatch['data'] as Map<String, dynamic>;
      });
    } catch (e, stackTrace) {
      logger.e("Firestore Error", error: e, stackTrace: stackTrace);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text(
            "Something went wrong while searching for the book.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
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
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _bookData != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
BoxShadow(
  color: const Color.fromRGBO(0, 0, 0, 0.2), // Equivalent to black with 20% opacity
  spreadRadius: 2,
  blurRadius: 8,
  offset: const Offset(0, 4), // Shadow below the image
),
                                ],
                              ),
                              child: Image.file(
                                _image!,
                                height: 220,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              _bookData!['title'] ?? '',
                              style: GoogleFonts.concertOne(
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Color(0xFF987554),
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "by ${_bookData!['author'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookDetailPage(
                                      bookData: _bookData!,
                                      allBooks: [],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward,
                                  color: Colors.grey),
                              label: const Text(
                                "Read more",
                                style: TextStyle(color: Colors.grey),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Tap below to scan or upload a book cover",
                          style: TextStyle(fontSize: 16),
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: "SCAN",
                  onTap: () => pickImage(ImageSource.camera),
                ),
                _ActionButton(
                  icon: Icons.photo_library,
                  label: "UPLOAD",
                  onTap: () => pickImage(ImageSource.gallery),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: _isPressed ? const Color(0xFF8B4513) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8B4513)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon,
                color: _isPressed ? Colors.white : const Color(0xFF8B4513)),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: _isPressed ? Colors.white : const Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
