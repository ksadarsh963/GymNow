import 'package:flutter/material.dart';

class CreateDietPlanScreen extends StatelessWidget {
  const CreateDietPlanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Diet Plan")),
      body: Center(
        child: Text(
          "Create Your Custom Diet Plan Here!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
