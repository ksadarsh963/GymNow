import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymnow/screen/feedback_screen.dart';
import 'screen/login_screen.dart';
import 'screen/user_dashboard.dart';
import 'screen/dashboard_redirect.dart'; // Import this to handle routing
import 'firebase_options.dart';
import 'package:gymnow/screen/user_management_screen.dart';
import 'package:gymnow/screen/gym_owner_management_screen.dart';
import 'package:gymnow/screen/gym_details_screen.dart';
import 'package:gymnow/screen/subscription_payments_screen.dart';
import 'package:gymnow/screen/app_content_management_screen.dart';
import 'package:gymnow/screen/system_health_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("🔥 Firebase Init Error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // ✅ FIX: If user exists, go to DashboardRedirect to handle role/profile checks
          if (snapshot.hasData) {
            return const DashboardRedirect(); 
          }
          // Otherwise, show Login
          return const LoginScreen();
        },
      ),
      routes: {
        '/userDashboard': (context) => const UserDashboard(),
        '/login': (context) => const LoginScreen(),
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