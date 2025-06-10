import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookEventPage extends StatefulWidget {
  final Map<String, dynamic> eventData;

  const BookEventPage({super.key, required this.eventData});

  @override
  _BookEventPageState createState() => _BookEventPageState();
}

class _BookEventPageState extends State<BookEventPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final eventName = event['event-name'] ?? 'Unknown Event';
    final eventDescription = event['event-description'] ?? 'No description available';
    final eventDate = event['event-date'] != null ? DateTime.parse(event['event-date']) : null;
    final eventVenue = event['event-venue'] ?? 'Unknown Venue';
    final eventBanner = event['event-banner'] ?? 'https://via.placeholder.com/150';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          eventName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: const Color(0xFF987554),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: eventBanner,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF987554),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                eventDescription,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Text(
                'Date',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF987554),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                eventDate != null ? DateFormat.yMMMd().format(eventDate) : 'Date not specified',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Text(
                'Venue',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF987554),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                eventVenue,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}