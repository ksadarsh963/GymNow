import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymnow/screen/user_profile_setup_screen.dart';
import '../services/auth_service.dart';
import 'user_dashboard.dart';
import 'dart:developer';

class DashboardRedirect extends StatefulWidget {
  const DashboardRedirect({super.key});

  @override
  State<DashboardRedirect> createState() => DashboardRedirectState();
}

class DashboardRedirectState extends State<DashboardRedirect> {
  String? userPhoneNumber;
  bool hasSubscription = false;
  bool hasWorkoutPlan = false;
  bool hasDietPlan = false;

@override
  void initState() {
    super.initState();
    _checkProfile(); // ✅ Moved inside the correct State class
    checkUserStatus();
  }

    @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _checkProfile() async {
  log("Checking profile...");
  bool hasProfile = await AuthService().userHasProfile();
  log("Profile check complete: $hasProfile");

  WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!hasProfile && mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserProfileSetupScreen()),
    );
  }
});}

void navigateToDashboard() {
  if (!mounted) return;

  log("🔀 Navigating to Dashboard...");

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => UserDashboard(
        phoneNumber: userPhoneNumber ?? "Unknown",
        hasSubscription: hasSubscription,
        hasWorkoutPlan: hasWorkoutPlan,
        hasDietPlan: hasDietPlan,
      ),
    ),
  );
}


Future<void> checkUserStatus() async {
  log("🔍 Checking user status...");
  String? userId = await AuthService().getCurrentUserId();

  if (userId == null) {
    log("❌ No user ID found!");
    return;
  }

  try {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      log("✅ User document found: ${userDoc.data()}");
      
      setState(() {
        userPhoneNumber = userDoc['phoneNumber'] as String?;
        hasSubscription = userDoc['hasSubscription'] ?? false;
        hasWorkoutPlan = userDoc['hasWorkoutPlan'] ?? false;
        hasDietPlan = userDoc['hasDietPlan'] ?? false;
      });

      navigateToDashboard();
    } else {
      log("⚠️ User document does not exist.");
    }
  } catch (e) {
    log("🚨 Error fetching user data: $e");
  }
}

}






