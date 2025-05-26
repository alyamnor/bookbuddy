// ocr_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>?> loadOCRResult(String filename) async {
  final String response = await rootBundle.loadString('assets/data/ocr_results.json');
  final List<dynamic> data = json.decode(response);

  return data.firstWhere(
    (entry) => entry['filename'] == filename,
    orElse: () => null,
  );
}
