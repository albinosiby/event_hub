import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_hub/pages/viewEvent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Listevent extends StatefulWidget {
  const Listevent({super.key});

  @override
  State<Listevent> createState() => _ListeventState();
}

class _ListeventState extends State<Listevent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),

            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Event List
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          userId != null
              ? FirebaseFirestore.instance.collection('events').snapshots()
              : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        // Filter events based on search query
        final filteredEvents =
            snapshot.data!.docs.where((doc) {
              final event = doc.data() as Map<String, dynamic>;
              final eventName =
                  event['eventName']?.toString().toLowerCase() ?? '';
              return eventName.contains(_searchQuery);
            }).toList();

        if (filteredEvents.isEmpty) {
          return const Center(child: Text('No matching events found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index].data() as Map<String, dynamic>;
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final dateTime = (event['eventDateTime'] as Timestamp).toDate();
    final eventType = event['eventType']?.toString() ?? 'default';

    // Define images for different event types
    final eventImages = {
      'Conference': 'assets/images/event/confre.jpeg',
      'default': 'assets/images/event/default.jpeg',
      'food fest': 'assets/images/event/food.jpg',
      'Exhibition': 'assets/images/event/exib.jpeg',
      'reception': 'assets/images/event/recep.jpeg',
      'Tech': 'assets/images/event/tech.jpeg',
      'music': 'assets/images/event/default.jpeg',
    };

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Viewevent(eventId: event['eventId']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side image (80x100)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  eventImages[eventType] ?? eventImages['default']!,
                  width: 85,
                  height: 95,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Right side content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date/Time row
                    Row(
                      children: [
                        Text(
                          DateFormat('d MMM').format(dateTime), // "13 MAY"
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A43EC),
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          ' - ',
                          style: TextStyle(color: Color(0xFF4A43EC)),
                        ),
                        Text(
                          DateFormat('EEE').format(dateTime), // "SAT"
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A43EC),
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          ' - ',
                          style: TextStyle(color: Color(0xFF4A43EC)),
                        ),
                        Text(
                          DateFormat('h:mm a').format(dateTime), // "2:00 PM"
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A43EC),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Event Name
                    Text(
                      event['eventName'] ?? 'Event Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Location (if available)
                    if (event['location'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event['location'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
