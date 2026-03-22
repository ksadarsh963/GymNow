import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'profile_setup_screen.dart';
// import 'workout_video_player.dart'; // Uncomment if you have this file

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  WorkoutPlanScreenState createState() => WorkoutPlanScreenState();
}

class WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  Map<String, dynamic> workoutPlan = {};
  bool isLoading = true;
  int currentDayIndex = 0;
  
  // FIX 1: Tracks the workout progress. -1 means "Day hasn't started yet".
  int currentWorkoutIndex = -1; 
  
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool isDayComplete = false;

  @override
  void initState() {
    super.initState();
    fetchWorkoutPlan();
  }

  Future<void> fetchWorkoutPlan() async {
    try {
      setState(() => isLoading = true);
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data() != null) {
        var userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('workout_plan')) {
          var planData = userData['workout_plan'];

          // FIX 2: Handle both Old and New AI structures
          Map<String, dynamic> rawRoutine;
          if (planData is Map<String, dynamic> && planData.containsKey('routine')) {
            rawRoutine = Map<String, dynamic>.from(planData['routine']);
          } else {
            rawRoutine = Map<String, dynamic>.from(planData);
          }

          // FIX 3: Sort Days (Day 1, Day 2...) to ensure correct order
          var sortedKeys = rawRoutine.keys.toList()..sort((a, b) => a.compareTo(b));
          Map<String, dynamic> sortedPlan = {
            for (var key in sortedKeys) key: rawRoutine[key]
          };

          setState(() {
            workoutPlan = sortedPlan;
          });
        }
      }
    } catch (e) {
      print("Error fetching plan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void startDay() {
    setState(() {
      currentWorkoutIndex = 0; // Move from -1 (Overview) to 0 (First Exercise)
    });
  }

  void completeWorkout() {
    if (workoutPlan.isEmpty) return;

    // Get current day's exercises
    List<dynamic> dayExercises = workoutPlan.values.elementAt(currentDayIndex);

    setState(() {
      if (currentWorkoutIndex < dayExercises.length - 1) {
        // Move to next exercise
        currentWorkoutIndex++;
      } else {
        // Day Complete!
        isDayComplete = true;
        currentWorkoutIndex = -1; // Reset for next day
        
        // Optional: Move to next day automatically or let user stay
        if (currentDayIndex < workoutPlan.length - 1) {
          currentDayIndex++;
          isDayComplete = false; // Reset for new day
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX 4: Handle Loading & Empty States safely
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (workoutPlan.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Plan")),
        body: const Center(child: Text("No workout plan found. Create one!")),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())),
        ),
      );
    }

    // Get Data safely
    String dayName = workoutPlan.keys.elementAt(currentDayIndex);
    List<dynamic> exercises = workoutPlan.values.elementAt(currentDayIndex);

    return Scaffold(
      appBar: AppBar(title: Text(dayName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (currentWorkoutIndex + 1) / (exercises.isEmpty ? 1 : exercises.length),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),

            // FIX 5: Logic to switch between "Overview" and "Active Exercise"
            Expanded(
              child: currentWorkoutIndex == -1
                  ? _buildDayOverview(exercises) // Show list if index is -1
                  : _buildActiveExercise(exercises[currentWorkoutIndex]), // Show item if index >= 0
            ),
          ],
        ),
      ),
      // Only show FAB if we are in "Overview" mode (-1) to edit plan
      floatingActionButton: currentWorkoutIndex == -1 
          ? FloatingActionButton(
              child: const Icon(Icons.edit),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())),
            )
          : null,
    );
  }

  // WIDGET 1: Day Overview (Shown when currentWorkoutIndex == -1)
  Widget _buildDayOverview(List<dynamic> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Routine", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              var ex = exercises[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text(ex['name'] ?? "Unknown Exercise"),
                  subtitle: Text("${ex['sets']} sets x ${ex['reps']} reps"),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: startDay, // Sets index to 0
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("START WORKOUT", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ),
      ],
    );
  }

  // WIDGET 2: Active Exercise (Shown when currentWorkoutIndex >= 0)
  Widget _buildActiveExercise(Map<String, dynamic> exercise) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          exercise['name'] ?? "Unknown",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          "${exercise['sets']} Sets  •  ${exercise['reps']} Reps",
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        
        // Video Player Placeholder
        // WorkoutVideoPlayer(videoUrl: exercise['videoUrl'] ?? ''),
        Container(
          height: 200,
          color: Colors.black12,
          child: const Center(child: Icon(Icons.play_circle_fill, size: 50, color: Colors.blue)),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: completeWorkout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("COMPLETE EXERCISE", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}