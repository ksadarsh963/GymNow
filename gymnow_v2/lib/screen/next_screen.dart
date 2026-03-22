import 'package:flutter/material.dart';
class NextScreen extends StatelessWidget {
  const NextScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Next Screen')),
      body: Center(child: Text('Welcome to Next Screen!')),
    );
  }
}
