import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profileview.dart';

class Notifi extends StatefulWidget {
  const Notifi({super.key});

  @override
  State<Notifi> createState() => _NotifiState();
}

class _NotifiState extends State<Notifi> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<Map<String, dynamic>> _followRequests = [];

  @override
  void initState() {
    super.initState();
    _loadFollowRequests();
  }

  Future<void> _loadFollowRequests() async {
    if (currentUserId == null) return;

    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

    if (currentUserDoc.exists) {
      final requestList = List<String>.from(
        currentUserDoc['followRequests'] ?? [],
      );

      if (requestList.isNotEmpty) {
        final usersSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: requestList)
                .get();

        setState(() {
          _followRequests =
              usersSnapshot.docs
                  .map((doc) => {...doc.data(), 'id': doc.id})
                  .toList();
        });
      }
    }
  }

  Future<void> _handleFollowBack(String userId) async {
    if (currentUserId == null) return;

    try {
      // Create a batch to perform all operations atomically
      final batch = FirebaseFirestore.instance.batch();

      // 1. Remove from current user's followRequests list
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(currentUserId),
        {
          'followRequests': FieldValue.arrayRemove([userId]),
        },
      );

      // 2. Update both users' followers/following arrays
      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'followers': FieldValue.arrayUnion([currentUserId]),
      });

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(currentUserId),
        {
          'following': FieldValue.arrayUnion([userId]),
        },
      );

      // 3. Create a mutual follow record
      batch.set(FirebaseFirestore.instance.collection('mutualFollows').doc(), {
        'user1': currentUserId,
        'user2': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Update local state
      setState(() {
        _followRequests.removeWhere((user) => user['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully followed back!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error following back: $e')));
    }
  }

  void _navigateToProfile(BuildContext context, String userId) {
    // Replace with your profile navigation logic
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Profileview(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body:
          _followRequests.isEmpty
              ? Center(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 90),
                      child: Image.asset(
                        'assets/images/Artwork.jpg',
                        height: 254,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Text(
                      'No Notifications!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _followRequests.length,
                itemBuilder: (context, index) {
                  final user = _followRequests[index];
                  final username = user['displayName'] ?? 'Unknown User';
                  final photoUrl = user['photoURL'];

                  return InkWell(
                    onTap: () => _navigateToProfile(context, user['id']),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child:
                              photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        title: Text('$username wants to follow you'),
                        subtitle: Text(
                          'Tap to view profile',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _handleFollowBack(user['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5669FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Follow Back'),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
