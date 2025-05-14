/*import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Center(child: Text('home')));
  }
}

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
);


deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  // Remove interest from Firebase
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(
                                        FirebaseAuth.instance.currentUser?.uid,
                                      )
                                      .update({
                                        'interests': FieldValue.arrayRemove([
                                          interest,
                                        ]),
                                      });
                                },
*/
