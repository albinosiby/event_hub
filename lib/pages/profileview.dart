import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_hub/pages/viewEvent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Profileview extends StatefulWidget {
  final String? userId; // Add this to view other users' profiles
  const Profileview({super.key, this.userId});

  @override
  State<Profileview> createState() => _ProfileviewState();
}

class _ProfileviewState extends State<Profileview>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });

        // Check if current user is following this profile
        if (widget.userId != null &&
            FirebaseAuth.instance.currentUser != null) {
          final currentUserDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get();

          final following = List<String>.from(
            currentUserDoc['following'] ?? [],
          );
          setState(() {
            _isFollowing = following.contains(widget.userId);
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final profileUserId = widget.userId;

      if (currentUserId == null || profileUserId == null) return;

      setState(() => _isLoading = true);

      if (_isFollowing) {
        // Unfollow
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(
            FirebaseFirestore.instance.collection('users').doc(profileUserId),
            {
              'followers': FieldValue.arrayRemove([currentUserId]),
            },
          );
          transaction.update(
            FirebaseFirestore.instance.collection('users').doc(currentUserId),
            {
              'following': FieldValue.arrayRemove([profileUserId]),
            },
          );
        });
      } else {
        // Follow
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(
            FirebaseFirestore.instance.collection('users').doc(profileUserId),
            {
              'followers': FieldValue.arrayUnion([currentUserId]),
            },
          );
          transaction.update(
            FirebaseFirestore.instance.collection('users').doc(currentUserId),
            {
              'following': FieldValue.arrayUnion([profileUserId]),
            },
          );
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating follow status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: SafeArea(
          child: Column(
            children: [
              // Profile Header Section
              _buildProfileHeader(),
              const SizedBox(height: 22),

              // Follow/Message Buttons
              if (widget.userId != null) _buildActionButtons(),
              const SizedBox(height: 25),

              // Tab Bar
              _buildTabBar(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(),
                    _buildEventsTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    //final followers = List<String>.from(_userData?['followers'] ?? []).length;
    //final following = List<String>.from(_userData?['following'] ?? []).length;
    final photoUrl =
        _userData?['photoUrl'] ?? FirebaseAuth.instance.currentUser?.photoURL;

    return Column(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child:
              photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
        ),
        const SizedBox(height: 20),
        Text(
          _userData?['displayName'] ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'No Name',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildStatsRow(0, 0),
      ],
    );
  }

  Widget _buildStatsRow(int followers, int following) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(followers.toString(), 'Followers'),
        const VerticalDivider(width: 30, thickness: 1),
        _buildStatItem(following.toString(), 'Following'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 55,
            child: _buildButton(
              text: _isFollowing ? 'Following' : 'Follow',
              icon: _isFollowing ? Icons.check : Icons.person_add,
              isPrimary: !_isFollowing,
              onPressed: _toggleFollow,
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 160,
            height: 55,
            child: _buildButton(
              text: 'Message',
              icon: Icons.message,
              isPrimary: false,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF5669FF) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF5669FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFF5669FF),
            width: isPrimary ? 0 : 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF5669FF),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        labelStyle: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w400),
        tabs: const [
          Tab(text: "ABOUT"),
          Tab(text: "EVENTS"),
          Tab(text: "REVIEWS"),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    final aboutText = _userData?['about'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aboutText != null && aboutText.isNotEmpty)
            Text(aboutText, style: const TextStyle(fontSize: 17))
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty_outlined,
                  size: 50,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No about information yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream:
          userId != null
              ? FirebaseFirestore.instance
                  .collection('events')
                  .where('organizerId', isEqualTo: userId)
                  .snapshots()
              : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final event =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
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

  Widget _buildReviewsTab() {
    // You can implement reviews fetching here similarly
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No reviews yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
