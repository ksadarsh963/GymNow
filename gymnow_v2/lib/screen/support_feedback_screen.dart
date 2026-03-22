import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportFeedbackScreen extends StatefulWidget {
  const SupportFeedbackScreen({super.key});
  @override
  SupportFeedbackScreenState createState() => SupportFeedbackScreenState();
}

class SupportFeedbackScreenState extends State<SupportFeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference feedbackRef =
      FirebaseFirestore.instance.collection('feedback');
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enter your feedback',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Submit Feedback'),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildFeedbackList()),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() async {
    if (_controller.text.isNotEmpty && userId != null) {
      try {
        // Fetch the username from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();
        String username = userDoc.exists ? userDoc['name'] ?? 'Unknown User' : 'Unknown User';

        // Save feedback to Firestore with username
        await feedbackRef.add({
          'username': username,
          'userId': userId,
          'message': _controller.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Clear input field after successful submission
        _controller.clear();

        // Show thank-you message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
          );
        }
      } catch (e) {
        debugPrint("❌ Error submitting feedback: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit feedback. Try again.')),
          );
        }
      }
    } else {
      // Show warning if input is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback before submitting.')),
      );
    }
  }

  Widget _buildFeedbackList() {
    if (userId == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: feedbackRef.where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('NO feedbacks yet'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No feedback available'));
        }

        final feedbackDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: feedbackDocs.length,
          itemBuilder: (context, index) {
            final feedback = feedbackDocs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(feedback['message'] ?? 'No message'),
              subtitle: Text(feedback['timestamp']?.toDate().toString() ?? 'No date'),
            );
          },
        );
      },
    );
  }
}
