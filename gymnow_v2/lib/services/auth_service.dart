import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<bool> userHasProfile() async {
    String? userId = await getCurrentUserId();
    if (userId == null) return false;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc.exists;
  }
  // ✅ Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return _auth.currentUser != null;
  }

  // ✅ Get current user ID
  Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    log("Current user: $user");
    return user?.uid;
  }

  // ✅ Sign In Function with Role Handling and Profile Check
  Future<Map<String, dynamic>?> signInUser(String email, String password) async {
    FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: false
);

  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;
    debugPrint("Fetching Firestore data for UID: $uid");

    // Fetch user data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    debugPrint("Firestore Document Data: ${userDoc.data()}");
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Ensure role is not null
      String role = userData['role'] ?? "user"; // Default to 'user' if missing
      bool isProfileComplete = userData['profileComplete'] ?? false;
    debugPrint("Firestore User Role: $role");

      return {
        "role": role,
        "profileComplete": isProfileComplete
      };
    }
   else{ return null;}
  } catch (e) {
    debugPrint("❌ Error in signInUser: $e");
    return null;
  }
}

  // ✅ Fetch User Role from Firestore
 Future<String?> getUserRole(String uid) async {
  try {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      debugPrint("❌ No document found for user ID: $uid");
      return "user"; // Default role
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return data['role'] ?? "user";
  } catch (e) {
    debugPrint("❌ Error fetching user role: $e");
    return "user";
  }
}


  // ✅ Check if User's Profile is Complete
  Future<bool> checkProfileCompletion(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        return data['profileSetup'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error checking profile completion: $e");
      return false;
    }
  }

  // ✅ Save User Physical Parameters & Mark Profile as Complete
  Future<void> saveUserPhysicalParameters(
      String uid, double height, double weight, int age) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'height': height,
        'weight': weight,
        'age': age,
        'profileSetup': true, // Mark profile as completed
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Error saving user parameters: $e");
      throw Exception("Failed to save user parameters: $e");
    }
  }

  // ✅ Sign Up Function (Store Role & Initial Data)
  Future<String?> signUpUser(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Store user role and initialize fields in Firestore
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'role': role.isNotEmpty ? role : "user", // Default to 'user'
        'hasSubscription': false,
        'profileSetup': false,
        'hasWorkoutPlan': false,
        'hasDietPlan': false,
      });

      return role.isNotEmpty ? role : "user";
    } catch (e) {
      debugPrint("❌ Error in signUpUser: $e");
      return null;
    }
  }

  // ✅ Sign Out Function
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Check if User has a Diet Plan
  Future<bool> hasDietPlan(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['hasDietPlan'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error checking diet plan: $e");
      return false;
    }
  }

  // ✅ Check if User has a Workout Plan
  Future<bool> hasWorkoutPlan(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['hasWorkoutPlan'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error checking workout plan: $e");
      return false;
    }
  }

  // ✅ Check if User has an Active Subscription
  Future<bool> hasSubscription(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['hasSubscription'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error checking subscription: $e");
      return false;
    }
  }

  // ✅ Generate Diet & Workout Plan Placeholder
  Future<void> generateDietAndWorkoutPlan(String userId) async {
    debugPrint("📌 Generating diet and workout plan for user: $userId");
    // 🔜 Implement logic for AI-generated plans
  }

  // ✅ Check Profile Setup Placeholder
  Future<bool> checkProfileSetup(String uid) async {
    // Your logic to check profile setup
  return true;
    // 🔜 Implement profile setup check logic
  }
  AuthService();
}







