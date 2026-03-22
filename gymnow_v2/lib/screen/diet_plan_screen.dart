import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});
  @override
  DietPlanScreenState createState() => DietPlanScreenState();
}

class DietPlanScreenState extends State<DietPlanScreen> {
  String? userId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
   List<Map<String, dynamic>>? dietPlan;

  @override
  void initState() {
    super.initState();
    _fetchDietPlan();
  }

 

 void _fetchDietPlan() async {
    User? user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;

      // Fetch user document from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      debugPrint("User Document: ${userDoc.data()}"); // Debugging output

      // Convert Firestore document data to a Map
      var userData = userDoc.data() as Map<String, dynamic>?;  
      if (userData != null) {
        var dietData = userData['diet_plan'];  // Get diet plan data

        if (dietData is List) {
          setState(() {
            dietPlan = dietData.cast<Map<String, dynamic>>(); // ✅ Corrected assignment
          });
        } else {
          debugPrint("Unexpected diet plan format: $dietData");
        }
      }
    }
  }




  void _toggleMealCompletion(int mealIndex) async {
  if (userId == null || dietPlan == null || mealIndex >= dietPlan!.length) return;

  setState(() {
    dietPlan![mealIndex]['completed'] = !(dietPlan![mealIndex]['completed'] ?? false);
  });

  await _firestore.collection('users').doc(userId).update({
    'diet_plan': dietPlan, // ✅ Update the entire list
  });
}

double _calculateProgress() {
  if (dietPlan == null || dietPlan!.isEmpty) return 0.0;
  
  int completedMeals = dietPlan!.where((meal) => meal['completed'] == true).length;
  return completedMeals / dietPlan!.length;
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Diet Plan Progress')),
    body: dietPlan == null
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(
                  value: _calculateProgress(),
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: dietPlan!.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> meal = dietPlan![index];

                    return Card(
                      child: ListTile(
                        title: Text(meal['name']?.toUpperCase() ?? 'Meal'),
                        subtitle: Text(meal['details'] ?? 'No details'),
                        trailing: Checkbox(
                          value: meal['completed'] ?? false,
                          onChanged: (_) => _toggleMealCompletion(index), // Pass index instead of String
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
  );
}
}
