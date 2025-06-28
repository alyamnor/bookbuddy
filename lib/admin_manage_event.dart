import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'book_event.dart';
// Make sure BookEventPage is defined in book_event.dart and exported properly.

class AdminManageEventPage extends StatefulWidget {
  const AdminManageEventPage({super.key});

  @override
  _AdminManageEventPageState createState() => _AdminManageEventPageState();
}

class _AdminManageEventPageState extends State<AdminManageEventPage> {
  final Logger _logger = Logger(printer: PrettyPrinter());
  final userId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (userId == null) {
      Fluttertoast.showToast(msg: 'Please log in to manage events');
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('event-database')
          .get();

      setState(() {
        events = snapshot.docs.map((doc) => {
          'eventId': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      _logger.e('Error fetching events', error: e);
      Fluttertoast.showToast(msg: 'Failed to load events');
    }
  }

  Future<void> _addEvent() async {
    if (userId == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final venueController = TextEditingController();
    final bannerController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Add Event',
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: const Color(0xFF987554),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Event Description',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Event Date (YYYY-MM-DD)',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    labelText: 'Event Venue',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bannerController,
                  decoration: InputDecoration(
                    labelText: 'Event Banner URL',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF987554)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && bannerController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('event-database').add({
                      'event-name': nameController.text.trim(),
                      'event-description': descriptionController.text.trim(),
                      'event-date': dateController.text.trim(),
                      'event-venue': venueController.text.trim(),
                      'event-banner': bannerController.text.trim(),
                    });
                    _fetchEvents();
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Event added successfully');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Failed to add event');
                  }
                } else {
                  Fluttertoast.showToast(msg: 'Please provide event name and banner URL');
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.poppins(color: const Color(0xFF987554)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editEvent(Map<String, dynamic> event) async {
    final nameController = TextEditingController(text: event['event-name']);
    final descriptionController = TextEditingController(text: event['event-description']);
    final dateController = TextEditingController(text: event['event-date']);
    final venueController = TextEditingController(text: event['event-venue']);
    final bannerController = TextEditingController(text: event['event-banner']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Edit Event',
            style: GoogleFonts.poppins(
              fontSize: 24,
              color: const Color(0xFF987554),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Event Name',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Event Description',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Event Date (YYYY-MM-DD)',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    labelText: 'Event Venue',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bannerController,
                  decoration: InputDecoration(
                    labelText: 'Event Banner URL',
                    labelStyle: GoogleFonts.poppins(color: const Color(0xFF987554)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF987554), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: const Color(0xFF987554)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && bannerController.text.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('event-database')
                        .doc(event['eventId'])
                        .update({
                      'event-name': nameController.text.trim(),
                      'event-description': descriptionController.text.trim(),
                      'event-date': dateController.text.trim(),
                      'event-venue': venueController.text.trim(),
                      'event-banner': bannerController.text.trim(),
                    });
                    _fetchEvents();
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Event updated successfully');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Failed to update event');
                  }
                } else {
                  Fluttertoast.showToast(msg: 'Please provide event name and banner URL');
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: const Color(0xFF987554)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(String eventId, String eventName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Remove Event',
          style: GoogleFonts.poppins(
            fontSize: 24,
            color: const Color(0xFF987554),
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$eventName" from events?',
          style: GoogleFonts.poppins(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF987554)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: const Color(0xFFFF0000)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('event-database')
            .doc(eventId)
            .delete();
        _fetchEvents();
        Fluttertoast.showToast(msg: 'Event removed');
      } catch (e) {
        _logger.e('Error removing event', error: e);
        Fluttertoast.showToast(msg: 'Failed to remove event');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF987554)),
            onPressed: _addEvent,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Manage Events',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    color: const Color(0xFF987554),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? const Center(child: Text('No events yet'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookEventPage(
                                    eventData: event,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey, width: 1.0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                    child: CachedNetworkImage(
                                      imageUrl: event['event-banner'] ?? 'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      height: 120,
                                      width: double.infinity,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        _logger.e('Failed to load event banner', error: error);
                                        return const Icon(Icons.broken_image, size: 50);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF987554),
                                            ),
                                            onPressed: () => _editEvent(event),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Color(0xFFFF0000),
                                          ),
                                          onPressed: () => _deleteEvent(event['eventId'], event['event-name'] ?? 'Unknown Event'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}