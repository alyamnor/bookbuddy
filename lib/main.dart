import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'BookBuddy',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto', 
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          backgroundColor: Color(0xFF8D6E63), // Soft Brown
        ),
        body: const Center(
          child: Text('Hello, world!'),
        ),
      ),
    ),
  );
}
