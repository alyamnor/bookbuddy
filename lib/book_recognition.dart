// book_recognition.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';

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
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pickImage(ImageSource.camera);
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      result = '';
      _isLoading = true;
    });

    final inputImage = InputImage.fromFilePath(_image!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
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
                onPressed: () => Navigator.pop(context), child: const Text("OK")),
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
    
    // Store potential matches with their scores
    List<Map<String, dynamic>> potentialMatches = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = (data['title'] as String?)?.toLowerCase() ?? '';
      final author = (data['author'] as String?)?.toLowerCase() ?? '';

      // Split OCR text into lines and filter out short or noisy text
      final textLines = text.split('\n').map((line) => line.trim()).where((line) => line.length > 3).toList();
      bool wordMatch = title.split(' ').where((word) => word.length > 3).any(
          (word) => textLines.any((line) => line.contains(word)));

      double titleScore = StringSimilarity.compareTwoStrings(text, title);
      double authorScore = StringSimilarity.compareTwoStrings(text, author);

      bool authorMatch = text.contains(author) || authorScore > 0.5; // Tighten threshold
      bool fuzzyTitleMatch = titleScore > 0.5; // Tighten threshold

      logger.i("Checking book: $title by $author");
      logger.i("Title score: $titleScore | Author score: $authorScore | WordMatch: $wordMatch");

      // Calculate a combined score (weighted: title is more important)
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
          content: const Text("Try scanning again or selecting a clearer image."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    // Sort matches by combined score and pick the best one
    potentialMatches.sort((a, b) => b['score'].compareTo(a['score']));
    final bestMatch = potentialMatches.first;

    logger.i("BEST MATCH: ${bestMatch['data']['title']} with score: ${bestMatch['score']}");

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BookDetailPage(
                bookData: bestMatch['data'] as Map<String, dynamic>,
                allBooks: snapshot.docs.map((doc) => doc.data()).toList(),
              )),
    );
  } catch (e, stackTrace) {
    logger.e("Firestore Error", error: e, stackTrace: stackTrace);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: const Text("Something went wrong while searching for the book."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Book Cover")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Select from Gallery"),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.file(_image!, height: 250),
                  ),
                const SizedBox(height: 10),
                Text(result, style: const TextStyle(fontSize: 16)),
              ],
            ),
    );
  }
}