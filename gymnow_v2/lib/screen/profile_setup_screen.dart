import 'package:flutter/material.dart';
import 'package:gymnow/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymnow/services/ai_service.dart';
// 1. IMPORT THE DESTINATION SCREEN
import 'workout_plan_screen.dart'; 

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Controllers for Inputs
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  
  String? selectedGender;
  String? selectedGoal;
  bool _isLoading = false;

  final List<String> genders = ["Male", "Female"];
  final List<String> fitnessGoals = ["Weight Loss", "Muscle Gain", "Maintain Fitness"];

  final GymAIService _aiService = GymAIService();

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  Future<void> generatePlan() async {
    if (ageController.text.isEmpty ||
        heightController.text.isEmpty ||
        weightController.text.isEmpty ||
        experienceController.text.isEmpty ||
        selectedGender == null ||
        selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? userId = await AuthService().getCurrentUserId();

      int age = int.parse(ageController.text);
      double height = double.parse(heightController.text);
      double weight = double.parse(weightController.text);
      int months = int.parse(experienceController.text); 
      int genderCode = (selectedGender == "Male") ? 1 : 0;

      // 2. GENERATE PLAN (OFFLINE AI)
      Map<String, dynamic> aiResult = await _aiService.generateWorkout(
        age: age,
        gender: genderCode,
        weight: weight,
        height: height,
        months: months,
        consistency: 1.0, 
        gap: 0,
      );

      // 3. SAVE TO FIRESTORE
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'age': age,
        'gender': selectedGender,
        'height': height,
        'weight': weight,
        'goal': selectedGoal,
        'months_experience': months,
        'workout_plan': aiResult, // AI Plan saved here
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Plan Generated: ${aiResult['split_name']}!")),
        );
        
        // 4. NAVIGATE TO WORKOUT SCREEN (The Fix)
        // pushReplacement removes the setup screen from the back stack
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WorkoutPlanScreen()),
        );
      }

    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's customize your AI Plan.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Age & Gender
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: "Age", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
                    items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => selectedGender = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Height & Weight
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Experience Input (Months)
            const Text("Experience Level", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            TextFormField(
              controller: experienceController,
              decoration: const InputDecoration(
                labelText: "Months of Gym Experience",
                hintText: "e.g. 0 for beginner, 24 for 2 years",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            // Goal Dropdown
            DropdownButtonFormField<String>(
              value: selectedGoal,
              decoration: const InputDecoration(labelText: "Primary Goal", border: OutlineInputBorder()),
              items: fitnessGoals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => selectedGoal = val),
            ),
            
            const SizedBox(height: 30),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: generatePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Generate AI Workout Plan", style: TextStyle(fontSize: 16)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}