import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'profileview.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _organizerId;

  bool _isFollowing = false;
  @override
  void initState() {
    super.initState();
    _eventFuture = _fetchEventDetails().then((eventDoc) {
      loadDetail();
      return eventDoc;
    });
  }

  Future<DocumentSnapshot> _fetchEventDetails() async {
    try {
      final eventDoc =
          await _firestore.collection('events').doc(widget.eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      _organizerId = eventData['organizerId'];

      if (_organizerId != null) {
        await _loadOrganizerDetails(_organizerId!);
      }

      return eventDoc;
    } catch (e) {
      throw Exception('Failed to load event: $e');
    }
  }

  Future<void> _loadOrganizerDetails(String organizerId) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(organizerId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _organizerName = userData['displayName'] ?? 'Unknown Organizer';
          _organizerProfileUrl = userData['photoURL'];
        });
      }
    } catch (e) {
      debugPrint('Error loading organizer details: $e');
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
            'Conference': 'assets/images/event/confre.jpeg',
            'default': 'assets/images/event/default.jpeg',
            'food fest': 'assets/images/event/food.jpg',
            'Exhibition': 'assets/images/event/exib.jpeg',
            'reception': 'assets/images/event/recep.jpeg',
            'Tech': 'assets/images/event/tech.jpeg',
            'music': 'assets/images/event/default.jpeg',
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
                        subtitle: DateFormat('EEEE, h:mma').format(dateTime),
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
                              if (_organizerId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            Profileview(userId: _organizerId!),
                                  ),
                                );
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child:
                                  _organizerProfileUrl != null &&
                                          _organizerProfileUrl!.isNotEmpty
                                      ? Image.network(
                                        _organizerProfileUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
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

                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _organizerName ??
                                            'Loading organizer...',
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
                                // Add follow button here
                                ElevatedButton(
                                  onPressed: _handleFollowOrganizer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _isFollowing
                                            ? Colors.grey
                                            : Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
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

  Future<void> loadDetail() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _organizerId == null) return;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _isFollowing =
              userData['following'] != null &&
              (userData['following'] as List).contains(_organizerId);
        });
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _handleFollowOrganizer() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _organizerId == null) return;

    try {
      final organizerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_organizerId);

      if (!_isFollowing) {
        // Follow logic
        await organizerRef.update({
          'followrequests': FieldValue.arrayUnion([currentUser.uid]),
        });
        setState(() {
          _isFollowing = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
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
