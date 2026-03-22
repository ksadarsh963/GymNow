import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackDisplayScreen extends StatefulWidget {
  const FeedbackDisplayScreen({super.key});

  @override
  FeedbackDisplayScreenState createState() => FeedbackDisplayScreenState();
}

class FeedbackDisplayScreenState extends State<FeedbackDisplayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Feedback')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedback')
            .orderBy('timestamp', descending: true) // Sort latest first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No feedback available.'));
          }

          var feedbackList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbackList.length,
            itemBuilder: (context, index) {
              var feedback = feedbackList[index];
              String username = feedback['username'] ?? 'Unknown User';
              String message = feedback['message'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(message),
                  leading: const Icon(Icons.feedback, color: Colors.blue),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
