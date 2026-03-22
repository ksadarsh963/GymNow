import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Map<String, dynamic> workoutProgress = {};
  List<dynamic> completedWorkouts = [];

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Progress"),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching progress data"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No progress data available"));
          }

          workoutProgress = snapshot.data!['workout_progress'] ?? {};
          completedWorkouts = snapshot.data!['completed_workouts']?[selectedDate] ?? [];

          double progress = (workoutProgress[selectedDate] ?? 0.0).toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressCircle(progress),
              const SizedBox(height: 20),
              const Text(
                "Completed Workouts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: completedWorkouts.isEmpty
                    ? const Center(child: Text("No workouts completed"))
                    : ListView.builder(
                        itemCount: completedWorkouts.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(completedWorkouts[index]['name'] ?? 'Unknown Workout'),
                            subtitle: Text(
                                "Sets: ${completedWorkouts[index]['sets']}, Reps: ${completedWorkouts[index]['reps']}"),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle(double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('dd MMM yyyy').format(DateTime.parse(selectedDate)),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: _getColorForProgress(progress),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress >= 0.75) {
      return Colors.green;
    } else if (progress >= 0.5) {
      return Colors.yellow;
    } else if (progress >= 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
