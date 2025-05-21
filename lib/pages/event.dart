import 'package:event_hub/pages/viewEvent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Event extends StatefulWidget {
  const Event({super.key});
  @override
  State<Event> createState() => EventState();
}

class EventState extends State<Event> {
  bool isUpcoming = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Toggle Buttons
          _buildToggleButtons(),
          const SizedBox(height: 20),

          // Event List
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      height: 45,
      width: 300,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isUpcoming = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isUpcoming ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow:
                      isUpcoming
                          ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'UPCOMING',
                  style: TextStyle(
                    color: isUpcoming ? const Color(0xFF4A43EC) : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isUpcoming = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isUpcoming ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow:
                      !isUpcoming
                          ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                          : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  'PAST EVENTS',
                  style: TextStyle(
                    color: !isUpcoming ? const Color(0xFF4A43EC) : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final now = DateTime.now();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('events')
              .orderBy('eventDateTime')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filter events based on toggle (upcoming/past) and organizer ID
        final events =
            snapshot.data!.docs.where((doc) {
              final event = doc.data() as Map<String, dynamic>;
              final eventTime = (event['eventDateTime'] as Timestamp).toDate();
              final organizerId = event['organizerId'] as String?;

              final isTimeValid =
                  isUpcoming ? eventTime.isAfter(now) : eventTime.isBefore(now);

              // Exclude events created by the current user
              final isNotCurrentUser = organizerId != currentUserId;

              return isTimeValid && isNotCurrentUser;
            }).toList();

        if (events.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index].data() as Map<String, dynamic>;
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
      'Workshop': 'assets/images/event/collab.png',
      'confre': 'assets/images/event/confre.jpeg',
      'default': 'assets/images/event/default.jpeg',
      'Meetup': 'assets/images/event/meetup.jpeg',
      'exibution': 'assets/images/event/exib.jpeg',
      'reception': 'assets/images/event/recep.jpeg',
      'Tech': 'assets/images/event/tech.jpeg',
    };
    print(event['name']);
    print(eventType);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Viewevent(eventId: event['eventId']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12), // Match card's border radius
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
                            fontSize: 15,
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
                            fontSize: 15,
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
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Event Name
                    Text(
                      event['eventName'] ?? 'Event Name',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Location (if available)
                    if (event['location'] != null) ...[
                      const SizedBox(height: 13),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/event.png',
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          Text(
            isUpcoming ? 'No Upcoming Events!' : 'No Past Events Found!',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
