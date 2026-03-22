import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DietInputScreen extends StatefulWidget {
  const DietInputScreen({super.key});
  @override
  DietInputScreenState createState() => DietInputScreenState();
}

class DietInputScreenState extends State<DietInputScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  String _selectedGoal = 'Muscle Gain';

  Future<void> _generateDietPlan() async {
    final String weight = _weightController.text.trim();
    final String targetWeight = _targetWeightController.text.trim();

    if (weight.isEmpty || targetWeight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final Uri url = Uri.parse('http://127.0.0.1:8000/generate_diet/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'goal': _selectedGoal,
        'weight': weight,
        'target_weight': targetWeight,
      }),
    );

    if (response.statusCode == 200) {
      final dietPlan = jsonDecode(response.body);
      await _saveDietPlanToFirestore(dietPlan);
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diet plan saved successfully')),
      );
    } else { if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate diet plan')),
      );
    }
  }

  Future<void> _saveDietPlanToFirestore(Map<String, dynamic> dietPlan) async {
    final String userId = 'userId'; // Replace with dynamic user ID fetching
    await FirebaseFirestore.instance
        .collection('nusers')
        .doc(userId)
        .update({'diet_plan': dietPlan});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate Diet Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _targetWeightController,
              decoration: InputDecoration(labelText: 'Target Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _selectedGoal,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGoal = newValue!;
                });
              },
              items: ['Muscle Gain', 'Muscle Loss']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateDietPlan,
              child: Text('Generate Diet Plan'),
            ),
          ],
        ),
      ),
    );
  }
}
