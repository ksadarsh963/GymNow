import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPaymentsScreen extends StatefulWidget {
  const SubscriptionPaymentsScreen({super.key}); // Corrected class name
  @override
  SubscriptionPaymentsScreenState createState() => SubscriptionPaymentsScreenState();
}

class SubscriptionPaymentsScreenState extends State<SubscriptionPaymentsScreen> {
  final CollectionReference subscriptionsRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription & Payments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: subscriptionsRef.where('hasSubscription', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching subscription data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active subscriptions found'));
          }

          final subscriptions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = subscriptions[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.payment, color: Colors.blueAccent),
                title: Text(subscription['name'] ?? 'No Name'),
                subtitle: Text('Plan: ${subscription['plan_name'] ?? 'N/A'}'),
                trailing: Text(
                  '₹${subscription['price'] ?? '0'}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showSubscriptionDetails(context, subscription),
              );
            },
          );
        },
      ),
    );
  }

  void _showSubscriptionDetails(BuildContext context, Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(subscription['name'] ?? 'Subscription Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan: ${subscription['plan_name'] ?? 'N/A'}'),
              Text('Price: ₹${subscription['price'] ?? '0'}'),
              Text('Start Date: ${subscription['start_date'] ?? 'N/A'}'),
              Text('Expiry Date: ${subscription['expiry_date'] ?? 'N/A'}'),
              Text('Status: ${subscription['isActive'] == true ? 'Active' : 'Inactive'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
