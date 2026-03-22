import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Required for image upload
import 'dart:io';
import 'user_dashboard.dart';

class UserProfileSetupScreen extends StatefulWidget {
  const UserProfileSetupScreen({super.key});

  @override
  UserProfileSetupScreenState createState() => UserProfileSetupScreenState();
}

class UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedGender;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false; 

  // 📸 Pick Image Function
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // 💾 Save Profile Function
  Future<void> _saveProfile() async {
    String name = _nameController.text.trim();
    String age = _ageController.text.trim();
    String phone = _phoneController.text.trim();

    // 1️⃣ Validation
    if (name.isEmpty || age.isEmpty || _selectedGender == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required (including gender)!")),
      );
      return;
    }

    setState(() => _isLoading = true); // Start loading

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      String photoUrl = "";

      // 2️⃣ Upload Image to Firebase Storage
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('$userId.jpg');

        // Upload the file first
        await storageRef.putFile(_profileImage!);
        
        // THEN get the download URL
        photoUrl = await storageRef.getDownloadURL();
      }

      // 3️⃣ Save Data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': name,
        'age': int.tryParse(age) ?? 0,
        'phoneNumber': phone,
        'gender': _selectedGender,
        'profilePhotoUrl': photoUrl,
        'profileComplete': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      
      // 4️⃣ Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserDashboard()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false); // Stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.cyan[50],
      appBar: AppBar(
        title: const Text("Setup Profile"),
        backgroundColor: Colors.cyan,
      ),
      // ✅ FIX 1: SingleChildScrollView prevents "Bottom Overflow" error
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null ? const Icon(Icons.camera_alt, size: 50) : null,
              ),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(_nameController, "Name"),
            _buildTextField(_ageController, "Age", isNumeric: true),
            
            // ✅ FIX 2: Fixed the "value is deprecated" error
            // ✅ FIX: GENDER DROPDOWN
           DropdownButtonFormField<String>(
           key: Key('gender_setup_$_selectedGender'), // Unique Key prevents duplications
           initialValue: _selectedGender,             // Use initialValue
           items: ["Male", "Female", "Other"].map((gender) {
               return DropdownMenuItem(value: gender, child: Text(gender));
            }).toList(),
           onChanged: (value) => setState(() => _selectedGender = value as String),
            decoration: const InputDecoration(labelText: "Gender", border: OutlineInputBorder()),
          ),
            
            const SizedBox(height: 10),
            _buildTextField(_phoneController, "Phone", isNumeric: true),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text("Save Profile"),
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
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
      ),
    );
  }
}