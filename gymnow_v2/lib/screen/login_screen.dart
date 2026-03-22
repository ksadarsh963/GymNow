import 'package:flutter/material.dart';
import 'package:gymnow/screen/admin_dashboard.dart';
import 'package:gymnow/screen/gym_owner_dashboard.dart';
import 'package:gymnow/screen/gym_owner_profile_setup_screen.dart';
import 'package:gymnow/services/auth_service.dart'; // Updated AuthService import
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'user_dashboard.dart'; // Ensure this exists and properly routes users
import 'user_profile_setup_screen.dart';
import 'dart:developer';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // ✅ Login Function
 Future<void> _login() async {
  setState(() => _isLoading = true);
  String input = _emailOrPhoneController.text.trim();
  String password = _passwordController.text.trim();

  if (input.isEmpty || password.isEmpty) {
    if (!mounted) return;  
    _showMessage("Email/Phone and Password are required.");
    setState(() => _isLoading = false);
    return;
  }

  if (!_isEmail(input) && !RegExp(r"^\d{10}$").hasMatch(input)) {
    if (!mounted) return;
    _showMessage("Enter a valid email or phone number.");
    setState(() => _isLoading = false);
    return;
  }

  try {
   var loginResult = await AuthService().signInUser(input, password);

    if (!mounted) return;  

    if (loginResult != null) {
      String role = loginResult["role"];
      bool? isProfileComplete = loginResult["profileComplete"];

      log("User Role: $role");
      debugPrint("Profile Complete Status: $isProfileComplete");
    
      debugPrint("🔹 User Role: $role");
      if (role == "admin") {
        // Directly navigate to Admin Dashboard
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      } else if ((role == "user") && isProfileComplete == true) {
        debugPrint("User Profile Complete: $isProfileComplete");
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => UserDashboard()),
        );
      } else if((role == "user")  && isProfileComplete == false){
        // Redirect to Profile Setup for user or gym owner
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => UserProfileSetupScreen()),
        );
      }
      else if (role == "gym_owner") {
        if (!mounted) return;
      // Fetch profile completion status
      debugPrint("Gym Owner Profile Complete: $isProfileComplete");

      if (isProfileComplete == true) {
        if (!mounted) return; 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GymOwnerDashboard()),
        );
      } else { if (!mounted) return; 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GymOwnerSetupScreen()),
        );
      }
    }
    } else {
      _showMessage("Login failed: Invalid credentials.");
    }
  } catch (e) {
    if (!mounted) return;
    _showMessage("Login failed: ${e.toString()}");
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}



  bool _isEmail(String input) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(input);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Displaying the Glossy Gradient Logo
             SizedBox(
              height: 120, // Adjust size as needed
              width: 120,
              child: Image.asset(
                'assets/logo_full.jpg', // <--- Your GLOSSY image
               fit: BoxFit.contain,
              ),
            ),
              const SizedBox(height: 15),
              const Text(
                "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyan),
              ),
              const SizedBox(height: 20),
              _buildInputField(_emailOrPhoneController, "Email or Phone"),
              const SizedBox(height: 10),
              _buildInputField(_passwordController, "Password", isPassword: true),
              const SizedBox(height: 15),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _login,
                        child: const Text("Login", style: TextStyle(fontSize: 16)),
                      ),
                    ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen())),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, {bool isPassword = false}) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
        obscureText: isPassword,
      ),
    );
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}






