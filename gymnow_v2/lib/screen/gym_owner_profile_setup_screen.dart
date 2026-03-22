import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GymOwnerSetupScreen extends StatefulWidget {
  const GymOwnerSetupScreen({super.key});
  @override
  GymOwnerSetupScreenState createState() => GymOwnerSetupScreenState();
}

class GymOwnerSetupScreenState extends State<GymOwnerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gymNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController upiIdController = TextEditingController();
  List<Map<String, String>> plans = [];

  void addPlan() {
    setState(() {
      plans.add({"name": "", "price": "", "duration": ""});
    });
  }

  void removePlan(int index) {
    setState(() {
      plans.removeAt(index);
    });
  }

  void saveGymOwnerDetails() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': nameController.text,
          'phone': phoneController.text,
          'gym_name': gymNameController.text,
          'location': {
            'city': cityController.text,
            'state': stateController.text,
            'country': countryController.text
          },
          'upi_id': upiIdController.text,
          'plans': plans,
          'role': 'gym_owner',
          'profileComplete': true,
        });
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/gymOwnerDashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gym Owner Profile Setup", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.cyan[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField("Full Name", nameController, Icons.person),
              buildTextField("Phone Number", phoneController, Icons.phone),
              buildTextField("Gym Name", gymNameController, Icons.fitness_center),
              buildTextField("City", cityController, Icons.location_city),
              buildTextField("State", stateController, Icons.map),
              buildTextField("Country", countryController, Icons.flag),
              buildTextField("UPI ID", upiIdController, Icons.account_balance_wallet),
              SizedBox(height: 20),
              Text("Plans Offered", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...plans.asMap().entries.map((entry) {
                int index = entry.key;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        buildPlanTextField("Plan Name", index, "name"),
                        buildPlanTextField("Price", index, "price"),
                        buildPlanTextField("Duration (Days)", index, "duration"),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removePlan(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: addPlan,
                icon: Icon(Icons.add),
                label: Text("Add Plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveGymOwnerDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  "Complete Setup",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.cyan[700]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget buildPlanTextField(String label, int index, String key) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (value) => plans[index][key] = value,
      ),
    );
  }
}

