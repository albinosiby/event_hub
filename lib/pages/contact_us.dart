import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: const Color(0xFF4A43EC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildSectionHeader('We\'d love to hear from you!'),
            const SizedBox(height: 20),

            // Contact Methods
            _buildContactCard(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'Send us an email directly',
              value: 'support@eventhub.com',
              onTap: () => 0,
            ),

            _buildContactCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: 'Available 9AM-5PM, Mon-Fri',
              value: '+19 1234567890',
              onTap: () => 0,
            ),

            _buildContactCard(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Instant support',
              value: 'Start Chat',
              onTap: () => _showLiveChat(context),
            ),

            _buildContactCard(
              icon: Icons.location_on,
              title: 'Visit Us',
              subtitle: 'Our office location',
              value: '123 Event St,Kochi,Kerala',
              onTap: () => 0,
            ),

            const SizedBox(height: 30),

            // FAQ Section
            _buildSectionHeader('Frequently Asked Questions'),
            _buildFAQItem(
              question: 'How do I create an event?',
              answer:
                  'Tap the + button on the home screen to create a new event.',
            ),
            _buildFAQItem(
              question: 'Can I sell tickets through EventHub?',
              answer: 'Yes! We support ticket sales with secure payments.',
            ),

            const SizedBox(height: 30),

            // Social Media
          ],
        ),
      ),
    );
  }

  // Helper Methods
  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A43EC),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF4A43EC)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(value, style: TextStyle(color: Colors.blue[700])),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(padding: const EdgeInsets.all(15), child: Text(answer)),
      ],
    );
  }

  void _showLiveChat(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Live Chat'),
            content: const Text(
              'Our support team will connect with you shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
