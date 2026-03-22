import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymnow/screen/feedback_screen.dart';
import 'package:gymnow/screen/login_screen.dart';
import 'package:gymnow/screen/user_management_screen.dart';
import 'package:gymnow/screen/gym_owner_management_screen.dart';
import 'package:gymnow/screen/gym_details_screen.dart';
import 'package:gymnow/screen/subscription_payments_screen.dart'; 
import 'package:gymnow/screen/app_content_management_screen.dart';
import 'package:gymnow/screen/system_health_screen.dart';

void main() => runApp(const AdminDashboardApp());

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AdminDashboard(),
        '/userManagement': (context) => const UserManagementScreen(),
        '/gymOwnerManagement': (context) => const GymOwnerManagementScreen(),
        '/gymDetails': (context) => const GymDetailsScreen(),
        '/subscriptionPayments': (context) => const SubscriptionPaymentsScreen(),
        '/appContentManagement': (context) => const AppContentManagementScreen(),
        '/supportFeedback': (context) => const FeedbackDisplayScreen(),
        '/systemHealth': (context) => const SystemHealthScreen(),
      },
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // FIX: Updated logout function to handle async gaps in a StatelessWidget
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); 
    
    // CHECK: Use 'context.mounted' instead of just 'mounted'
    if (!context.mounted) return; 

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), 
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), 
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 2.5,
          children: [
            _buildDashboardCard(context, 'User Management', Icons.people, '/userManagement'),
            _buildDashboardCard(context, 'Gym Owner Management', Icons.business, '/gymOwnerManagement'),
            _buildDashboardCard(context, 'Gym Details', Icons.fitness_center, '/gymDetails'),
            _buildDashboardCard(context, 'Subscription & Payments', Icons.payment, '/subscriptionPayments'),
            _buildDashboardCard(context, 'App Content Management', Icons.article, '/appContentManagement'),
            _buildDashboardCard(context, 'Support & Feedback', Icons.support_agent, '/supportFeedback'),
            _buildDashboardCard(context, 'System Health', Icons.health_and_safety, '/systemHealth'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 4.0,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40.0, color: Colors.blueAccent),
              const SizedBox(height: 8.0),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}