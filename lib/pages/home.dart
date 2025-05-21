// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_hub/pages/viewEvent.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:event_hub/auth.dart'; // Make sure you have this import for AuthService
import 'package:intl/intl.dart';
import 'profile.dart';
import 'map.dart';
import 'event.dart';
import 'notification.dart';
import 'login/loginPage.dart';
import 'contact_us.dart';
import 'create_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currenttab = 0;
  final List<Widget> screens = [HomeContent(), map(), Event(), Profile()];
  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = const HomeContent();
  final User? user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(bucket: bucket, child: currentScreen),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateEventScreen()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF4A43EC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: _buildDrawer(context),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.explore,
                  color:
                      currenttab == 0 ? const Color(0xFF4A43EC) : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    currentScreen = const HomeContent();
                    currenttab = 0;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.event,
                  color:
                      currenttab == 1 ? const Color(0xFF4A43EC) : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    currentScreen = const Event();
                    currenttab = 1;
                  });
                },
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.location_on_sharp,
                  color:
                      currenttab == 2 ? const Color(0xFF4A43EC) : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    currentScreen = const map();
                    currenttab = 2;
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color:
                      currenttab == 3 ? const Color(0xFF4A43EC) : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    currentScreen = const Profile();
                    currenttab = 3;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.displayName ?? 'Guest User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.email ?? 'No email provided',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child:
                  user?.photoURL == null
                      ? const Icon(Icons.person, size: 48, color: Colors.grey)
                      : null,
            ),
            decoration: const BoxDecoration(color: Color(0xFF4A43EC)),
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'My Profile',
            onTap: () {
              Navigator.pop(context);
              setState(() {
                currentScreen = const Profile();
                currenttab = 3;
              });
            },
          ),
          _buildDrawerItem(
            icon: Icons.message,
            title: 'Messages',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Contact Us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactUsScreen()),
              );
              // Add navigation to contact us screen
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _authService.logout();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
      ),
      onTap: onTap,
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(179),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4A43EC),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(33),
              bottomRight: Radius.circular(33),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 45, left: 23, right: 23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  width: 354,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        color: Colors.white,
                        iconSize: 28,
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const Text(
                        'Event Hub',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_on),
                        color: Colors.white,
                        iconSize: 28,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Notifi()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 40,
                  width: 327,
                  child: Row(
                    children: [
                      const SizedBox(width: 15),
                      const Icon(Icons.search, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 28, color: Colors.white54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          textAlign: TextAlign.start,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 20,
                              color: Colors.white54,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 19),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          backgroundColor: const Color.fromARGB(39, 0, 0, 0),
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onPressed: () {
                          print('Filter button tapped');
                        },
                        child: const Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Upcoming Events Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Event()),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF4A43EC),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildupcoming(),
            // Nearby Events Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Events Near You',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to nearby events page
                      //Navigator.push(
                      //context,
                      //MaterialPageRoute(builder: (context) => NearbyEventsPage()),
                      //);
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Color(0xFF4A43EC), fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            _buildNearby(),
          ],
        ),
      ),
    );
  }

  Widget _buildupcoming() {
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

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No upcoming events'));
        }

        final events = snapshot.data!.docs;

        return SizedBox(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              final eventTime = (event['eventDateTime'] as Timestamp).toDate();

              if (event['organizerId'] == currentUserId ||
                  eventTime.isBefore(DateTime.now())) {
                return const SizedBox();
              } else {
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

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => Viewevent(eventId: events[index].id),
                      ),
                    );
                  },
                  child: Container(
                    width: 230,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              children: [
                                // Event Image
                                Container(
                                  height: 140,
                                  width: 218,
                                  color: Colors.grey[200],
                                  child: Image.asset(
                                    eventImages[eventType] ??
                                        eventImages['default']!,
                                    height: 140,
                                    width: 218,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                // Top-left date badge
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          DateFormat('d').format(dateTime),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMMM')
                                              .format(dateTime)
                                              .toUpperCase(), // e.g. JUNE
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                //  Top-right bookmark icon
                                /* Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.bookmark,
                                      color: Colors.redAccent,
                                      size: 16,
                                    ),
                                  ),
                                ),*/
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            bottom: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Event Title with ellipsis
                              Text(
                                event['eventName'] ?? 'Event Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 8),

                              // Location
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 17,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      // ignore: prefer_interpolation_to_compose_strings
                                      event['venue'] +
                                              ',' +
                                              event['location'] ??
                                          'Location not specified',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildNearby() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5, // Replace with your actual event count
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: Image.asset(
                    'assets/images/event.png', // Replace with your image path
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Event ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Location',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Date & Time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
}
