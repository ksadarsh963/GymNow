import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'support_feedback_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _selectedGender = data['gender'] ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String name = _nameController.text.trim();
    String age = _ageController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || age.isEmpty || _selectedGender == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': name,
        'age': int.tryParse(age) ?? 0,
        'phoneNumber': phone,
        'gender': _selectedGender,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            ListView(
              children: [
                _buildTextField(_nameController, "Name"),
                _buildTextField(_ageController, "Age", isNumeric: true),
                // ✅ FIX: EDIT PROFILE GENDER DROPDOWN
              DropdownButtonFormField<String>(
               key: Key('gender_edit_$_selectedGender'), // Unique Key
               initialValue: _selectedGender,            // Use initialValue
               items: ["Male", "Female", "Other"].map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
                 onChanged: (value) => setState(() => _selectedGender = value as String),
                 decoration: const InputDecoration(labelText: "Gender"),
              ),
                _buildTextField(_phoneController, "Phone", isNumeric: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: ElevatedButton.icon(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text("Sign Out"),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20, // Placing in the bottom-right corner
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportFeedbackScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.feedback),
                label: const Text("Feedback"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
