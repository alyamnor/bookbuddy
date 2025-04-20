import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FetchDataFromfirebase extends StatefulWidget {
  const FetchDataFromfirebase({super.key});

  @override
  State<FetchDataFromfirebase> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<FetchDataFromfirebase> {
  final CollectionReference fetchData = 
  FirebaseFirestore.instance.collection("Book Database");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Fetch Data from Firebase"),
      ),
      body: StreamBuilder(stream: fetchData.snapshots(), builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
        if (streamSnapshot.hasError) {
          return const Center(child: Text("Error"));
        } else if (streamSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (streamSnapshot.hasData) {
          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = streamSnapshot.data!.docs[index];
              return ListTile(
                title: Text(data['Book Name']),
                subtitle: Text(data['Author Name']),
              );
            },
          );
        } else {
          return const Center(child: Text("No Data Found"));
        }
      }),
    );
  }
}
