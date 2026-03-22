import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'profile_setup_screen.dart';
import 'diet_plan_screen.dart';
import 'workout_plan_screen.dart';
import 'find_gym_screen.dart';
import 'user_profile_screen.dart';
import 'progress_screen.dart';
import 'diet_input_screen.dart';

class UserDashboard extends StatefulWidget {
  final bool hasSubscription;
  final bool hasWorkoutPlan;
  final bool hasDietPlan;
  final String? phoneNumber;

  const UserDashboard({
    super.key,
    this.hasSubscription = false,
    this.hasWorkoutPlan = false,
    this.hasDietPlan = false,
    this.phoneNumber,
  });

  @override
  UserDashboardState createState() => UserDashboardState();
}

class UserDashboardState extends State<UserDashboard> {
  bool hasDietPlan = false;
  bool hasWorkoutPlan = false;
  bool hasSubscription = false;
  bool isProfileComplete = false;
  Map<String, double> progressData = {};

  @override
  void initState() {
    super.initState();
    checkUserStatus();
    loadProgressData();
  }

  void checkUserStatus() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          isProfileComplete = docSnapshot.data()?['profileComplete'] ?? false;
          hasDietPlan = docSnapshot.data()?['hasDietPlan'] ?? false;
          hasWorkoutPlan = docSnapshot.data()?['hasWorkoutPlan'] ?? false;
          hasSubscription = docSnapshot.data()?['hasSubscription'] ?? false;
        });
      }
    });
  }

  Future<void> loadProgressData() async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  try {
    QuerySnapshot progressSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();

    Map<String, double> tempData = {};

    for (var doc in progressSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Ensure 'completion' is present, else assign 0.0
      double completion = (data.containsKey('completion') && data['completion'] != null)
          ? data['completion'].toDouble()
          : 0.0;

      tempData[doc.id] = completion;
    }

    // Assign default value for 'workout_progress' if not found
    tempData.putIfAbsent('workout_progress', () => 0.0);

    setState(() {
      progressData = tempData;
    });
  } catch (e) {
    debugPrint("Error loading progress data: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        children: [
          const Text("Calendar Progress",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildCalendarProgress(),
          const SizedBox(height: 20),

          if (hasWorkoutPlan)
            _buildImageCard("Workout Plan", "assets/workplan.jpg", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutPlanScreen()),
              );
            }),

          if (hasDietPlan)
            _buildImageCard("Diet Plan", "assets/dietplan.jpg", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DietPlanScreen()),
              );
            }),

          if (!hasWorkoutPlan)
            _buildImageCard("Create Workout Plan", "assets/workplan.jpg", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              );
            }),

          if (!hasDietPlan)
            _buildImageCard("Create Diet Plan", "assets/dietplan.jpg", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DietInputScreen()),
              );
            }),

          if (hasSubscription)
            _buildImageCard("Manage Subscription", "assets/findgym.jpg", () {}),

          _buildImageCard("Find Gym", "assets/findgym.jpg", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FindGymScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.asset(
              imagePath,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              fit: BoxFit.cover,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildCalendarProgress() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("User not logged in"));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Default empty data if nothing exists
        Map<String, dynamic> workoutProgress = {};
        if (snapshot.hasData && snapshot.data!.exists) {
           var data = snapshot.data!.data() as Map<String, dynamic>;
           workoutProgress = data['workout_progress'] ?? {};
        }

        // ✅ FIX: Always generate 7 days, defaulting to 0.0 if no data
        List<String> sortedDates = workoutProgress.keys.toList()..sort();
        
        // If no dates, start from today backwards
        DateTime anchorDate = sortedDates.isNotEmpty 
            ? DateTime.parse(sortedDates.first) 
            : DateTime.now().subtract(const Duration(days: 6));

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            DateTime date = anchorDate.add(Duration(days: index));
            String dateKey = DateFormat('yyyy-MM-dd').format(date);
            double progress = (workoutProgress[dateKey] ?? 0.0).toDouble();

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProgressScreen(),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(date), // Show Day Number (e.g., 5)
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getColorForProgress(progress),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        color: progress > 0.5 ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}










