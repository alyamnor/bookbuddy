import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FetchDataFromFirebase extends StatefulWidget {
  const FetchDataFromFirebase({super.key});

  @override
  State<FetchDataFromFirebase> createState() => _FetchDataFromfirebaseState();
}

class _FetchDataFromfirebaseState extends State<FetchDataFromFirebase> {
  final CollectionReference fetchData =
      FirebaseFirestore.instance.collection("Book Database");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Fetch Data from Firebase"),
      ),
      body: StreamBuilder(
        stream: fetchData.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        documentSnapshot['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      subtitle: Text(documentSnapshot['author']),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
