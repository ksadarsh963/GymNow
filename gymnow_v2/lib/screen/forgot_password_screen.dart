import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

 Future<void> _resetPassword() async {
  String input = _emailOrPhoneController.text.trim();

  if (input.isEmpty) {
    if (!mounted) return; // ✅ Prevents using context if widget is disposed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter your email or phone number.")),
    );
    return;
  }

  try {
    if (_isEmail(input)) {
      await _auth.sendPasswordResetEmail(email: input);
      if (!mounted) return; // ✅ Check again before using context
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number verification required to reset password.")),
      );
    }
    if (mounted) {
      Navigator.pop(context); // ✅ Safe to call only if still mounted
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
}


  bool _isEmail(String input) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}").hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Colors.orangeAccent,
      ),
      backgroundColor: const Color(0xFFFFF3E0), // Light orange theme
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Enter your email or phone number to reset password",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300, // Reduce input field width
                child: TextField(
                  controller: _emailOrPhoneController,
                  decoration: const InputDecoration(labelText: "Email or Phone"),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200, // Reduce button width
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Reset Password", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



