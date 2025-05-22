import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildProfileUI(null);
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            return _buildProfileUI(userData);
          },
        ),
      ),
    );
  }

  Widget _buildProfileUI(Map<String, dynamic>? userData) {
    final aboutText = userData?['about'] as String? ?? 'No bio added yet';
    final interests = List<String>.from(userData?['interests'] ?? []);
    final followers = List<String>.from(userData?['followers'] ?? []).length;
    final following = List<String>.from(userData?['following'] ?? []).length;
    final Name = userData?['displayName'] as String? ?? 'unknown';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child:
                  user?.photoURL == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
            ),
          ),
          const SizedBox(height: 20),

          // Display Name
          Text(
            Name,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Stats Section
          _buildStatsSection(followers, following),
          const SizedBox(height: 20),

          // Edit Profile Button
          _buildEditButton(),
          const SizedBox(height: 20),

          // About Section
          _buildAboutSection(aboutText, interests),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int followers, int following) {
    return Container(
      width: 180,
      height: 55,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  followers.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Followers',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              alignment: Alignment.topCenter,
              width: 1,
              height: 40,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(
                  following.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Following',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: 165,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(.5),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfile()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF5669FF), width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_square, color: Color(0xFF5669FF)),
              const SizedBox(width: 4),
              Text(
                'Edit profile',
                style: TextStyle(color: Color(0xFF5669FF), fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(String? aboutText, List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About Me',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Text(
            aboutText ?? 'Add your about to let others know you better',
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w400),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Interest',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (interests.isEmpty)
          const Text('Add some interests to let others know you better')
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children:
                interests
                    .map(
                      (interest) => Chip(
                        label: Text(interest),
                        backgroundColor: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
