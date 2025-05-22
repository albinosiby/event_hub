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
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadFollowRequests();
    _loadNotifications();
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
        currentUserDoc['followrequests'] ?? [],
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

  Future<void> _loadNotifications() async {
    if (currentUserId == null) return;

    final currentUserDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

    if (currentUserDoc.exists) {
      setState(() {
        _notifications = List<String>.from(
          currentUserDoc['notifications'] ?? [],
        );
      });
    }
  }

  Future<void> _clearAllNotifications() async {
    if (currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'notifications': []});

      setState(() {
        _notifications.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing notifications: $e')),
      );
    }
  }

  Future<void> _handleFollowBack(String userId) async {
    if (currentUserId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(currentUserId),
        {
          'followrequests': FieldValue.arrayRemove([userId]),
          'followers': FieldValue.arrayUnion([userId]),
        },
      );

      batch.update(FirebaseFirestore.instance.collection('users').doc(userId), {
        'following': FieldValue.arrayUnion([currentUserId]),
      });

      await batch.commit();

      setState(() {
        _followRequests.removeWhere((user) => user['id'] == userId);
      });

      // Add notification for both users
      final currentUser =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
      final otherUser =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      final currentUserName = currentUser['displayName'] ?? 'Someone';
      final otherUserName = otherUser['displayName'] ?? 'Someone';

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'notifications': FieldValue.arrayUnion([
              '$currentUserName has accepted your follow request',
            ]),
          },
        );
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(currentUserId),
          {
            'notifications': FieldValue.arrayUnion([
              'You are now following $otherUserName',
            ]),
          },
        );
      });

      // Reload notifications
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error following back: $e')));
    }
  }

  void _navigateToProfile(BuildContext context, String userId) {
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
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body:
          _followRequests.isEmpty && _notifications.isEmpty
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
              : ListView(
                children: [
                  if (_followRequests.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Follow Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ..._followRequests.map((user) {
                          final username =
                              user['displayName'] ?? 'Unknown User';
                          final photoUrl = user['photoURL'];

                          return InkWell(
                            onTap:
                                () => _navigateToProfile(context, user['id']),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
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
                                  onPressed:
                                      () => _handleFollowBack(user['id']),
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
                                  child: const Text('Accept'),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        const Divider(),
                      ],
                    ),
                  if (_notifications.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ..._notifications.reversed.map((notification) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.notifications),
                              title: Text(notification),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  setState(() {
                                    _notifications.remove(notification);
                                  });
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(currentUserId)
                                      .update({
                                        'notifications': FieldValue.arrayRemove(
                                          [notification],
                                        ),
                                      });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
    );
  }
}
