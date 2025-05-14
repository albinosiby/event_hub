import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'profileview.dart';

class Viewevent extends StatefulWidget {
  final String eventId;
  const Viewevent({super.key, required this.eventId});

  @override
  State<Viewevent> createState() => _VieweventState();
}

class _VieweventState extends State<Viewevent> {
  late Future<DocumentSnapshot> _eventFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _organizerName;
  String? _organizerProfileUrl;
  String? uid;

  @override
  void initState() {
    super.initState();
    _eventFuture = _fetchEventDetails();
  }

  Future<DocumentSnapshot> _fetchEventDetails() async {
    final eventDoc =
        await _firestore.collection('events').doc(widget.eventId).get();
    final eventData = eventDoc.data() as Map<String, dynamic>;
    final organizerId = eventData['organizerId'];
    if (organizerId != null) {
      await _loadOrganizerDetails(organizerId);
    }
    print(organizerId);
    uid = organizerId;
    return eventDoc;
  }

  Future<void> _loadOrganizerDetails(String organizerId) async {
    final userDoc = await _firestore.collection('users').doc(organizerId).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        _organizerName = userData['displayName'] ?? 'unknown';
        _organizerProfileUrl = userData['photoURL'] ?? userData['profileUrl'];
      });
      print(_organizerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 26,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Event not found'));
          }

          final event = snapshot.data!.data() as Map<String, dynamic>;
          final dateTime = (event['eventDateTime'] as Timestamp).toDate();
          final eventType = event['eventType']?.toString() ?? 'default';
          final eventImages = {
            'Workshop': 'assets/images/event/collab.png',
            'confre': 'assets/images/event/confre.jpeg',
            'default': 'assets/images/event/default.jpeg',
            'Meetup': 'assets/images/event/meetup.jpeg',
            'exibution': 'assets/images/event/exib.jpeg',
            'reception': 'assets/images/event/recep.jpeg',
            'Tech': 'assets/images/event/tech.jpeg',
          };

          return SingleChildScrollView(
            child: Stack(
              children: [
                // Event Image
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          eventImages[eventType] ?? eventImages['default']!,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Event Details
                Padding(
                  padding: const EdgeInsets.only(
                    top: 300,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Title
                      Text(
                        event['eventName'] ?? 'Event Name',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Date and Time
                      _buildInfoRow(
                        icon: 'assets/images/Date.png',
                        title: DateFormat('dd MMMM, yyyy').format(dateTime),
                        subtitle:
                            '${DateFormat('EEEE, h:mma').format(dateTime)} - ${DateFormat('h:mma').format(dateTime.add(const Duration(hours: 3)))}',
                      ),
                      const SizedBox(height: 30),

                      // Location
                      _buildInfoRow(
                        icon: 'assets/images/Location.png',
                        title: event['venue'] ?? 'Venue not specified',
                        subtitle: event['location'] ?? 'Location not specified',
                      ),
                      const SizedBox(height: 30),

                      // Organizer
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile image with GestureDetector
                          GestureDetector(
                            onTap: () {
                              print("Organizer image tapped");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => Profileview(
                                        userId: event['organizerId'],
                                      ),
                                ),
                              );
                            },
                            //organizerId: organizerId
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child:
                                  _organizerProfileUrl != null
                                      ? Image.network(
                                        _organizerProfileUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'assets/images/th.jpeg',
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'assets/images/th.jpeg',
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Organizer Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _organizerName ?? 'Loading organizer...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'Organizer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Follow Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                86,
                                106,
                                255,
                                0.532,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              // Follow functionality
                            },
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Color.fromARGB(162, 0, 0, 0),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),
                      const Text(
                        'About Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // About Content
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event['description'] ??
                              'No description available for this event.',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(icon, width: 48, height: 48, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
