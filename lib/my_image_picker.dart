import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:logger/logger.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'book_detail.dart';

class MyImagePicker extends StatefulWidget {
  const MyImagePicker({super.key});

  @override
  State<MyImagePicker> createState() => _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  File? _image;
  File? _processedImage;
  String _detectedTitle = '';
  String _detectedAuthor = '';
  String _ocrText = '';
  bool _isLoading = false;
  bool _useHighContrast = false;
  Map<String, dynamic>? _bookData;
  List<Map<String, dynamic>> _allBooks = [];
  final logger = Logger();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  Future<File> _preprocessImage(
    File imageFile,
    RecognizedText? recognizedText,
  ) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Dynamic cropping based on text regions if available
    if (recognizedText != null && recognizedText.blocks.isNotEmpty) {
      int minX = image.width, minY = image.height, maxX = 0, maxY = 0;
      for (var block in recognizedText.blocks) {
        minX = min(minX, block.boundingBox.left.toInt());
        minY = min(minY, block.boundingBox.top.toInt());
        maxX = max(maxX, block.boundingBox.right.toInt());
        maxY = max(maxY, block.boundingBox.bottom.toInt());
      }
      final padding = 20;
      minX = max(0, minX - padding);
      minY = max(0, minY - padding);
      maxX = min(image.width, maxX + padding);
      maxY = min(image.height, maxY + padding);
      image = img.copyCrop(
        image,
        x: minX,
        y: minY,
        width: maxX - minX,
        height: maxY - minY,
      );
    }

    // Grayscale
    image = img.grayscale(image);

    // Adaptive thresholding or minimal processing
    if (_useHighContrast) {
      image = img.adjustColor(image, contrast: 2.0, brightness: 30);
      image = img.sobel(image, amount: 0.3);
    } else {
      image = img.adjustColor(image, contrast: 1.2);
    }

    // Save processed image with unique file name
    final tempDir = await getTemporaryDirectory();
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempPath = '${tempDir.path}/processed_image_$uniqueId.png';
    final processedFile = File(tempPath)
      ..writeAsBytesSync(img.encodePng(image));

    logger.i("Processed image saved to: $tempPath");
    return processedFile;
  }

  String _cleanOcrText(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _processedImage = null;
      _detectedTitle = '';
      _detectedAuthor = '';
      _ocrText = '';
      _bookData = null;
      _isLoading = true;
    });

    logger.i("New image picked: ${_image!.path}");

    try {
      // Initial OCR to detect text regions
      final inputImage = InputImage.fromFilePath(_image!.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText initialText = await textRecognizer.processImage(
        inputImage,
      );

      // Preprocess image with text region data
      _processedImage = await _preprocessImage(_image!, initialText);
      final processedInput = InputImage.fromFilePath(_processedImage!.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        processedInput,
      );
      _ocrText = _cleanOcrText(recognizedText.text);
      final scannedText = _ocrText.toLowerCase();
      logger.i("OCR Result: $scannedText");

      // Detect title and author
      final textAnalysis = _analyzeTextBlocks(recognizedText);
      _detectedTitle = textAnalysis['title'] ?? '';
      _detectedAuthor = textAnalysis['author'] ?? '';

      // Fetch all books for recommendations, including ID
      final snapshot =
          await FirebaseFirestore.instance.collection('book-database').get();
      _allBooks = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      await _searchBookWithML(scannedText, _detectedTitle, _detectedAuthor);
      await textRecognizer.close();

      setState(() {
        // Ensure the UI updates with the new processed image
        _processedImage = File(_processedImage!.path);
      });
    } catch (e, stackTrace) {
      logger.e(
        "Image Processing or OCR Error",
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _showErrorDialog(source);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, String> _analyzeTextBlocks(RecognizedText recognizedText) {
    String title = '';
    String author = '';
    double maxScore = 0;

    final imageWidth =
        _image!.lengthSync() > 0
            ? (img.decodeImage(_image!.readAsBytesSync())?.width ?? 1)
            : 1;
    final imageHeight =
        _image!.lengthSync() > 0
            ? (img.decodeImage(_image!.readAsBytesSync())?.height ?? 1)
            : 1;
    final centerX = imageWidth / 2;
    final centerY = imageHeight / 2;

    for (var block in recognizedText.blocks) {
      final text = _cleanOcrText(block.text);
      if (text.length < 4 || RegExp(r'^\d+$').hasMatch(text)) continue;

      final height = block.boundingBox.height;
      final centerDistance = sqrt(
        pow(block.boundingBox.center.dx - centerX, 2) +
            pow(block.boundingBox.center.dy - centerY, 2),
      );
      final score = height / (centerDistance + 1);

      if (score > maxScore) {
        maxScore = score;
        title = text;
      } else if (block.boundingBox.top >
          recognizedText.blocks.first.boundingBox.top) {
        author = text;
      }
    }

    logger.i("Detected Title: $title, Detected Author: $author");
    return {'title': title, 'author': author};
  }

  Future<void> _searchBookWithML(
    String scannedText,
    String detectedTitle,
    String detectedAuthor,
  ) async {
    try {
      List<Map<String, dynamic>> potentialMatches = [];

      for (var doc in _allBooks) {
        final title = (doc['title'] as String?)?.toLowerCase() ?? '';
        final author = (doc['author'] as String?)?.toLowerCase() ?? '';

        final textLines =
            scannedText
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.length > 3)
                .toList();
        bool wordMatch = title
            .split(' ')
            .where((word) => word.length > 3)
            .any((word) => textLines.any((line) => line.contains(word)));

        double titleScore = StringSimilarity.compareTwoStrings(
          detectedTitle.isEmpty ? scannedText : detectedTitle.toLowerCase(),
          title,
        );
        double authorScore = StringSimilarity.compareTwoStrings(
          detectedAuthor.isEmpty ? scannedText : detectedAuthor.toLowerCase(),
          author,
        );

        int levenshteinDistance(String s1, String s2) {
          s1 = s1.toLowerCase();
          s2 = s2.toLowerCase();
          if (s1.isEmpty) return s2.length;
          if (s2.isEmpty) return s1.length;
          final List<List<int>> matrix = List.generate(
            s1.length + 1,
            (i) => List<int>.filled(s2.length + 1, 0),
          );
          for (int i = 0; i <= s1.length; i++) matrix[i][0] = i;
          for (int j = 0; j <= s2.length; j++) matrix[0][j] = j;
          for (int i = 1; i <= s1.length; i++) {
            for (int j = 1; j <= s2.length; j++) {
              int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
              matrix[i][j] = min(
                min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
                matrix[i - 1][j - 1] + cost,
              );
            }
          }
          return matrix[s1.length][s2.length];
        }

        double levenshteinScore =
            1 -
            (levenshteinDistance(
                  detectedTitle.isEmpty ? scannedText : detectedTitle,
                  title,
                ) /
                max(title.length, scannedText.length));

        final features = [
          titleScore,
          authorScore,
          wordMatch ? 1.0 : 0.0,
          detectedTitle.isNotEmpty ? 1.0 : 0.0,
          detectedAuthor.isNotEmpty ? 1.0 : 0.0,
          levenshteinScore,
        ];

        const weights = [0.35, 0.15, 0.15, 0.05, 0.05, 0.25];
        const bias = -0.2;
        double score = bias;
        for (int i = 0; i < features.length; i++) {
          score += features[i] * weights[i];
        }
        score = 1 / (1 + exp(-score));

        logger.i(
          "Checking book: ${doc['title']} by ${doc['author']} | ML Score: $score | Levenshtein: $levenshteinScore",
        );

        if (score > 0.5 || wordMatch) {
          potentialMatches.add({
            'data': doc,
            'score': score,
            'titleScore': titleScore,
            'authorScore': authorScore,
          });
        }
      }

      if (potentialMatches.isEmpty) {
        if (!mounted) return;
        _showErrorDialog(null);
        return;
      }

      potentialMatches.sort((a, b) => b['score'].compareTo(a['score']));
      final bestMatch = potentialMatches.first;

      logger.i(
        "Best Match: ${bestMatch['data']['title']} with score: ${bestMatch['score']}",
      );

      if (!mounted) return;
      setState(() {
        _bookData = bestMatch['data'] as Map<String, dynamic>;
      });
    } catch (e, stackTrace) {
      logger.e("Firestore Error", error: e, stackTrace: stackTrace);
      if (!mounted) return;
      _showErrorDialog(null);
    }
  }

  void _showErrorDialog(ImageSource? source) {
    _titleController.text = _detectedTitle;
    _authorController.text = _detectedAuthor;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("No Match Found"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("OCR Result: $_ocrText"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Corrected Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Corrected Author',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text("Use High Contrast Preprocessing"),
                    value: _useHighContrast,
                    onChanged:
                        (value) => setState(() => _useHighContrast = value!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed:
                    source != null
                        ? () {
                          Navigator.pop(context);
                          pickImage(source);
                        }
                        : null,
                child: const Text("Retry"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _searchBookWithML(
                    _titleController.text.toLowerCase() +
                        ' ' +
                        _authorController.text.toLowerCase(),
                    _titleController.text,
                    _authorController.text,
                  );
                },
                child: const Text("Search Manually"),
              ),
            ],
          ),
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
          Expanded(
            child: Center(
              child:
                  _isLoading
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
                                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child:
                                _processedImage != null
                                    ? Image.file(
                                      _processedImage!,
                                      height: 220,
                                      width: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.file(
                                        _image!,
                                        height: 220,
                                        width: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : Image.file(
                                      _image!,
                                      height: 220,
                                      width: 150,
                                      fit: BoxFit.cover,
                                    ),
                          ),
                          Text(
                            _bookData!['title'] ?? 'Unknown Title',
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
                            "by ${_bookData!['author'] ?? 'Unknown Author'}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Scanned Text:",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _ocrText.isEmpty ? 'No text detected' : _ocrText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Determine searchType dynamically based on OCR output
                              String searchType = 'title'; // Default
                              if (_bookData!.containsKey('author') && _bookData!['author'] != null && _bookData!['author'].isNotEmpty) {
                                searchType = 'author';
                              } else if (_bookData!.containsKey('genre') && _bookData!['genre'] != null && _bookData!['genre'].isNotEmpty) {
                                searchType = 'genre';
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailPage(
                                    bookData: _bookData!,
                                    allBooks: _allBooks,
                                    processedImage: _processedImage,
                                    searchType: searchType, // Add valid searchType
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.grey,
                            ),
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
          ),
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
            Icon(
              widget.icon,
              color: _isPressed ? Colors.white : const Color(0xFF8B4513),
            ),
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