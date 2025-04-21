import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'fetch_data_fromfirebase.dart';

Future<void> main() async {
  //Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const BookGridByCategory(),
    );
  }
}