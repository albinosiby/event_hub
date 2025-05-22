import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_hub/pages/viewEvent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Profileview extends StatefulWidget {
  final String? userId;
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
  bool _isCurrentUser = false;
  bool _hasRequested = false;

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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final profileUserId = widget.userId ?? currentUserId;

      if (profileUserId == null) return;

      setState(() {
        _isCurrentUser = currentUserId == profileUserId;
      });
      // Load profile data
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(profileUserId)
              .get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
        });
      }
      if (!_isCurrentUser && currentUserId != null) {
        await _checkFollowStatus(currentUserId, profileUserId);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  Future<void> _checkFollowStatus(
    String currentUserId,
    String profileUserId,
  ) async {
    // Check if current user is following profile user
    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
    final profileUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(profileUserId)
            .get();
    final following = List<String>.from(currentUserDoc['following'] ?? []);
    final followRequests = List<String>.from(
      profileUserDoc['followrequests'] ?? [],
    );
    setState(() {
      _isFollowing = following.contains(profileUserId);
      _hasRequested = followRequests.contains(currentUserId);
    });
  }

  Future<void> _sendFollowRequest() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final profileUserId = widget.userId;
      if (currentUserId == null || profileUserId == null) return;
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Add to profile user's follow requests
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(profileUserId),
          {
            'followrequests': FieldValue.arrayUnion([currentUserId]),
          },
        );
      });
      setState(() {
        _isLoading = false;
        _hasRequested = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Follow request sent')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final profileUserId = widget.userId;
      if (currentUserId == null || profileUserId == null) return;
      setState(() => _isLoading = true);
      if (_isFollowing) {
        // Unfollow logic
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(
            FirebaseFirestore.instance.collection('users').doc(currentUserId),
            {
              'following': FieldValue.arrayRemove([profileUserId]),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Profile Header Section
            _buildProfileHeader(),
            const SizedBox(height: 22),

            // Follow/Message Buttons
            if (!_isCurrentUser && widget.userId != null) _buildActionButtons(),
            const SizedBox(height: 25),

            // Tab Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF5669FF),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: "ABOUT"),
                  Tab(text: "EVENTS"),
                  Tab(text: "REVIEWS"),
                ],
              ),
            ),

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
    );
  }

  Widget _buildProfileHeader() {
    final followers = List<String>.from(_userData?['followers'] ?? []).length;
    final following = List<String>.from(_userData?['following'] ?? []).length;
    final photoUrl = _userData?['photoURL'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
            child:
                photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                    : null,
          ),
          const SizedBox(height: 20),
          Text(
            _userData?['displayName'] ?? 'No Name',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStatsRow(followers, following),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int followers, int following) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(followers.toString(), 'Followers'),
        const SizedBox(width: 30),
        _buildStatItem(following.toString(), 'Following'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildFollowButton()),
          const SizedBox(width: 15),
          Expanded(child: _buildMessageButton()),
        ],
      ),
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed:
            _isLoading
                ? null
                : () {
                  if (_hasRequested) {
                    return;
                  } else if (_isFollowing) {
                    _toggleFollow();
                  } else {
                    _sendFollowRequest();
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(),
          foregroundColor: _getTextColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF5669FF),
              width: _shouldShowBorder() ? 1 : 0,
            ),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getButtonIcon(), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getButtonText(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
      ),
    );
  }

  Color _getButtonColor() {
    if (_isFollowing) {
      return Colors.white;
    }
    return const Color(0xFF5669FF);
  }

  Color _getTextColor() {
    if (_isFollowing) {
      return const Color(0xFF5669FF);
    }
    return Colors.white;
  }

  bool _shouldShowBorder() {
    return _hasRequested || _isFollowing;
  }

  IconData _getButtonIcon() {
    if (_hasRequested) {
      return Icons.hourglass_top;
    } else if (_isFollowing) {
      return Icons.check;
    }
    return Icons.person_add;
  }

  String _getButtonText() {
    if (_hasRequested) {
      return 'Requested';
    } else if (_isFollowing) {
      return 'Following';
    }
    return 'Follow';
  }

  Widget _buildMessageButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5669FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF5669FF), width: 1),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 20),
            SizedBox(width: 8),
            Text('Message', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    final aboutText = _userData?['about']?.trim(); // Trim whitespace
    final bool hasAboutText = aboutText != null && aboutText.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Content
          if (hasAboutText)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              child: Text(
                aboutText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5, // Better line spacing
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No information yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This user hasn\'t shared any details',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

          // Additional sections could be added here
          if (hasAboutText) const SizedBox(height: 24),
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
    final eventImages = {
      'Conference': 'assets/images/event/confre.jpeg',
      'default': 'assets/images/event/default.jpeg',
      'food fest': 'assets/images/event/food.jpg',
      'Exhibition': 'assets/images/event/exib.jpeg',
      'reception': 'assets/images/event/recep.jpeg',
      'Tech': 'assets/images/event/tech.jpeg',
      'music': 'assets/images/event/default.jpeg',
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
