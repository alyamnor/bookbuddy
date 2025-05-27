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
  final logger = Logger();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => pickImage(ImageSource.camera));
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      result = '';
    });

    final inputImage = InputImage.fromFilePath(_image!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    await textRecognizer.close();

    final scannedText = recognizedText.text.toLowerCase();
    logger.i("OCR Result: $scannedText");

    await _searchBook(scannedText);
  }

  Future<void> _searchBook(String text) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('book-database').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title']?.toLowerCase() ?? '';
      final author = data['author']?.toLowerCase() ?? '';

      bool wordMatch = title
          .split(' ')
          .where((word) => word.length > 3)
          .any((word) => text.contains(word));

      double titleScore = StringSimilarity.compareTwoStrings(text, title);
      double authorScore = StringSimilarity.compareTwoStrings(text, author);

      bool authorMatch = text.contains(author) || authorScore > 0.6;
      bool fuzzyTitleMatch = titleScore > 0.5;

      if (wordMatch || authorMatch || fuzzyTitleMatch) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(bookData: data)),
        );
        return;
      }
    }

    setState(() => result = "❌ No matching book found.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Book Cover")),
      body: Column(
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
