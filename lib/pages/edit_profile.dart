import 'package:event_hub/pages/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _interestController = TextEditingController();
  List<String> interests = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _aboutController.text = data['about'] ?? '';
          if (data['interests'] != null) {
            interests = List<String>.from(data['interests']);
          }
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isEmpty) return;

    if (interests.contains(interest)) {
      _showErrorSnackbar('This interest already exists');
      return;
    }

    setState(() {
      interests.add(interest);
      _interestController.clear();
      _hasChanges = true;
    });
  }

  void _removeInterest(String interest) {
    setState(() {
      interests.remove(interest);
      _hasChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'about': _aboutController.text.trim(),
        'interests': interests,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _hasChanges = false);
    } catch (e) {
      _showErrorSnackbar('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      onChanged: () => setState(() => _hasChanges = true),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // About Section
                            TextFormField(
                              controller: _aboutController,
                              decoration: const InputDecoration(
                                labelText: 'About',
                                hintText: 'Tell us about yourself',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                contentPadding: EdgeInsets.all(16),
                              ),
                              maxLines: 5,
                              minLines: 3,
                              validator: (value) {
                                if (value != null && value.length > 500) {
                                  return 'About section should be less than 500 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Interests Section
                            const Text(
                              'Interests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your interests to help others know you better',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (interests.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    interests
                                        .map(
                                          (interest) => Chip(
                                            label: Text(interest),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                            onDeleted:
                                                () => _removeInterest(interest),
                                          ),
                                        )
                                        .toList(),
                              ),

                            const SizedBox(height: 16),

                            // Add Interest Input
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _interestController,
                                    decoration: InputDecoration(
                                      labelText: 'Add Interest',
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: _addInterest,
                                      ),
                                    ),
                                    onFieldSubmitted: (_) => _addInterest(),
                                    validator: (value) {
                                      if (value != null &&
                                          value.trim().isNotEmpty &&
                                          value.length > 30) {
                                        return 'Interest should be less than 30 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Press enter or the + icon to add',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              height: 50,
                              width: 60,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4A43EC),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Save Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
