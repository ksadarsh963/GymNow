import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_setup_screen.dart';
import 'package:intl/intl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> saveWorkoutProgress(String todayDate) async {
  String userId = FirebaseAuth.instance.currentUser!.uid;
  DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(userDoc);
    if (!mounted) return;
    if (!snapshot.exists) {
      // If user document does not exist, create it with workout_progress as a map
      transaction.set(userDoc, {
        'workout_progress': {
          todayDate: 0.0,  // Ensure it's stored as a Map<String, dynamic>
        }
      });
    } else {
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;

      if (userData.containsKey('workout_progress')) {
        // If workout_progress exists and is already a Map, update it
        if (userData['workout_progress'] is Map<String, dynamic>) {
          Map<String, dynamic> workoutProgress = Map<String, dynamic>.from(userData['workout_progress']);
          workoutProgress[todayDate] = 0.0; // Add today's progress

          transaction.update(userDoc, {
            'workout_progress': workoutProgress,
          });
        } else {
          // If workout_progress exists but is not a Map, overwrite it as a Map
          transaction.update(userDoc, {
            'workout_progress': {
              todayDate: 0.0
            },
          });
        }
      } else {
        // If workout_progress does not exist, create it
        transaction.update(userDoc, {
          'workout_progress': {
            todayDate: 0.0
          },
        });
      }
    }
  }).catchError((error) {
    debugPrint("Error saving workout progress: $error");
  });
  debugPrint("Saving workout progress for $todayDate");

}

  Future<void> _signup() async {
    // ❌ REMOVED: await saveWorkoutProgress(todayDate); 
    // Reason: You cannot save progress for a user that doesn't exist yet!

    if (!_formKey.currentState!.validate()) return;

    String input = _emailOrPhoneController.text.trim();
    String password = _passwordController.text.trim();
    bool isEmail = input.contains('@');

    try {
      UserCredential userCredential;

      if (isEmail) {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: input,
          password: password,
        );
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: "$input@phone.auth", 
          password: password,
        );
      }

      // ✅ FIX: Initialize 'workout_progress' here directly
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        isEmail ? 'email' : 'phone': input,
        'role': 'user',
        'profileSetup': false,
        'hasWorkoutPlan': false,
        'hasDietPlan': false,
        'hasSubscription': false,
        'createdAt': FieldValue.serverTimestamp(),
        // ✅ Added this line to prevent the "Bad State" error
        'workout_progress': {
           todayDate: 0.0, 
        }, 
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileSetupScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailOrPhoneController,
                decoration: InputDecoration(
                  labelText: 'Email or Phone Number',
                  prefixIcon: Icon(Icons.person, color: Colors.cyan),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter Email or Phone Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.cyan),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Signup', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}













