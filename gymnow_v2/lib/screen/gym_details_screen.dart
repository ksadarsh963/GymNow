import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GymDetailsScreen extends StatefulWidget {
  const GymDetailsScreen({super.key});
  @override
  GymDetailsScreenState createState() => GymDetailsScreenState();
}

class GymDetailsScreenState extends State<GymDetailsScreen> {
  final CollectionReference gymsRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gym Details')),
      body: StreamBuilder<QuerySnapshot>(
        stream: gymsRef.where('role', isEqualTo: 'gym_owner').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching gym details'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No gyms found'));
          }

          final gyms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Icon(Icons.fitness_center, color: Colors.blueAccent),
                title: Text(gym['gym_name'] ?? 'No Gym Name'),
                subtitle: Text('Owner: ${gym['name'] ?? 'No Owner Name'}'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showGymDetails(context, gym),
              );
            },
          );
        },
      ),
    );
  }

  void _showGymDetails(BuildContext context, Map<String, dynamic> gym) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(gym['gym_name'] ?? 'Gym Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Owner: ${gym['name'] ?? 'N/A'}'),
              Text('Location: ${gym['location'] ?? 'N/A'}'),
              Text('Contact: ${gym['phone'] ?? 'N/A'}'),
              Text('Status: ${gym['status'] == true ? 'Active' : 'Inactive'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
