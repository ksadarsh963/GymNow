import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});
  @override
  SystemHealthScreenState createState() => SystemHealthScreenState();
}

class SystemHealthScreenState extends State<SystemHealthScreen> {
  int totalUsers = 0;
  int totalGymOwners = 0;
  int activeSessions = 0;

  @override
  void initState() {
    super.initState();
    _fetchSystemHealthData();
  }

  Future<void> _fetchSystemHealthData() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final gymOwnersSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'gym_owner').get();
    final activeSessionsSnapshot = await FirebaseFirestore.instance.collection('active_sessions').get();

    setState(() {
      totalUsers = usersSnapshot.docs.length;
      totalGymOwners = gymOwnersSnapshot.docs.length;
      activeSessions = activeSessionsSnapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('System Health')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Health Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _buildHealthCard('Total Users', totalUsers),
            _buildHealthCard('Total Gym Owners', totalGymOwners),
            _buildHealthCard('Active Sessions', activeSessions),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchSystemHealthData,
              child: Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, int count) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(Icons.health_and_safety, color: Colors.blueAccent),
        title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        trailing: Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }
}
