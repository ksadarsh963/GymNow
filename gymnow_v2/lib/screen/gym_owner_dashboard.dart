// Assuming necessary imports are in place
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'support_feedback_screen.dart';

class GymOwnerDashboard extends StatefulWidget {
  const GymOwnerDashboard({super.key});
  @override
  GymOwnerDashboardState createState() => GymOwnerDashboardState();
}

class GymOwnerDashboardState extends State<GymOwnerDashboard> {
  String selectedOption = 'Subscriptions';
  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Owner Dashboard'),
        backgroundColor: Colors.cyan[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback),
            tooltip: "Feedback",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportFeedbackScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: getSelectedWidget(),
          ),
          BottomNavigationBar(
            currentIndex: getCurrentIndex(),
            onTap: onOptionSelected,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.subscriptions), label: 'Subscriptions'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }

  int getCurrentIndex() {
    switch (selectedOption) {
      case 'Notifications':
        return 1;
      case 'Profile':
        return 2;
      default:
        return 0;
    }
  }

  void onOptionSelected(int index) {
    setState(() {
      selectedOption = ['Subscriptions', 'Notifications', 'Profile'][index];
    });
  }

  Widget getSelectedWidget() {
    switch (selectedOption) {
      case 'Notifications':
        return buildNotificationWidget();
      case 'Profile':
        return buildProfileWidget();
      default:
        return buildSubscriptionWidget();
    }
  }

  Widget buildSubscriptionWidget() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('subscriptions')
          .where('gymOwnerId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No Subscriptions Found'));
        }
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              title: Text(doc['userName'] ?? 'Unknown User'),
              subtitle: Text('Plan: ${doc['planName']}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildNotificationWidget() {
    TextEditingController messageController = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: messageController,
            decoration: InputDecoration(
              labelText: 'Enter Message',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              String message = messageController.text.trim();
              if (message.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('subscriptions')
                    .where('gymOwnerId', isEqualTo: user?.uid)
                    .get()
                    .then((querySnapshot) {
                  for (var doc in querySnapshot.docs) {
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .add({
                      'userId': doc['userId'],
                      'message': message,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  }
                });
              }
            },
            child: Text('Send Notification'),
          ),
        ],
      ),
    );
  }

  Widget buildProfileWidget() {
    TextEditingController nameController = TextEditingController();
    TextEditingController gymNameController = TextEditingController();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          nameController.text = data['name'] ?? '';
          gymNameController.text = data['gym_name'] ?? '';

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: gymNameController,
                  decoration: InputDecoration(labelText: 'Gym Name'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .update({
                      'name': nameController.text,
                      'gym_name': gymNameController.text,
                    });
                  },
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text('Sign Out'),
                ),
              ],
            ),
          );
        } else {
          return Center(child: Text('Profile not found'));
        }
      },
    );
  }
}
