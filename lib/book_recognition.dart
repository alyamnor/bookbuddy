import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_detail.dart';

class MyImagePicker extends StatefulWidget {
  const MyImagePicker({super.key});

  @override
  State<MyImagePicker> createState() => _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  File? _image;
  String result = '';

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

    final inputImage = InputImage.fromFile(_image!);
    final recognizer = GoogleMlKit.vision.textRecognizer();
    final text = await recognizer.processImage(inputImage);
    await recognizer.close();

    await _searchBook(text.text.toLowerCase());
  }

  Future<void> _searchBook(String text) async {
    final snapshot = await FirebaseFirestore.instance.collection('book-database').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title']?.toLowerCase() ?? '';
      final author = data['author']?.toLowerCase() ?? '';

      if (text.contains(title) || text.contains(author)) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailPage(bookData: data)));
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
