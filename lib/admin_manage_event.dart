import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'book_event.dart';

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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(70),
                topRight: Radius.circular(70),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Add Event',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF987554),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Name',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Description',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Date (YYYY-MM-DD)',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Venue',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Banner URL',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: bannerController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.rubik(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF987554),
                          border: Border.all(
                            color: const Color(0xFF987554),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.rubik(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(70),
                topRight: Radius.circular(70),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Edit Event',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF987554),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Name',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Description',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Date (YYYY-MM-DD)',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Venue',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Event Banner URL',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF987554),
                    ),
                  ),
                ),
                TextField(
                  controller: bannerController,
                  decoration: InputDecoration(
                    hintStyle: GoogleFonts.roboto(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.rubik(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF987554),
                          border: Border.all(
                            color: const Color(0xFF987554),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.rubik(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
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
          style: GoogleFonts.rubik(
            fontSize: 16,
            color: const Color(0xFF987554),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $eventName from events?',
          style: GoogleFonts.roboto(color: Colors.black87, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.rubik(
                color: const Color(0xFFFF0000),
                fontWeight: FontWeight.bold,
              ),
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
icon: const Icon(
              Icons.add_box_rounded,
              color: Color(0xFF987554),
              size: 30,
            ),            onPressed: _addEvent,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Manage Events',
                  style: GoogleFonts.rubik(
                    fontSize: 30,
                    color: const Color(0xFF987554),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? const Center(
                        child: Text(
                          'No events yet',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
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
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: event['event-banner'] ?? 'https://via.placeholder.com/150',
                                      fit: BoxFit.cover,
                                      height: 100,
                                      width: double.infinity,
                                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) {
                                        _logger.e('Failed to load event banner', error: error);
                                        return const Icon(Icons.broken_image, size: 50);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 2.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(
                                                event['event-name'] ?? 'Unknown Event',
                                                style: GoogleFonts.rubik(
                                                  fontSize: 16,
                                                  color: const Color(0xFF000000),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Color(0xFF987554),
                                                size: 30,
                                              ),
                                              onPressed: () => _editEvent(event),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color(0xFFFF0000),
                                                size: 30,
                                              ),
                                              onPressed: () => _deleteEvent(
                                                event['eventId'],
                                                event['event-name'] ?? 'Unknown Event',
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
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