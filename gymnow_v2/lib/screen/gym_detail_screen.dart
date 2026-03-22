import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'payment_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gym_owner_dashboard.dart';

class GymDetailScreen extends StatefulWidget {
  final String gymId; // gymId is the same as gymOwnerId

  const GymDetailScreen({super.key, required this.gymId});

  @override
  GymDetailScreenState createState() => GymDetailScreenState();
}

class GymDetailScreenState extends State<GymDetailScreen> {
  String? receiverName; // Nullable
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    // Log the value of gymId
    debugPrint("GymDetailScreen initialized with gymId: ${widget.gymId}");

    fetchGymOwnerDetails();
  }

  Future<void> fetchGymOwnerDetails() async {
    try {
      debugPrint("Fetching gym owner details for gymId: ${widget.gymId}");
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.gymId) // Directly fetch the document using gymId
          .get();

      if (userDoc.exists) {
        // Debugging each field
        debugPrint("Document data: ${userDoc.data()}");

        // Check and log the role field
        final role = userDoc['role'] ?? 'unknown';
        debugPrint("Document role: $role");

        if (role != 'gym_owner') {
          debugPrint("Error: Document role is not gym_owner.");
          setState(() {
            isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Role is not gym_owner.')),
            );
          });
          return;
        }

        // Check and log the name field
        receiverName = userDoc['name'] ?? 'Unknown'; // Fallback to 'Unknown'
        debugPrint("'name': $receiverName");

        setState(() {
          isLoading = false;
        });
      } else {
        debugPrint("No gym owner found with the given ID.");
        setState(() {
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No gym owner found with the given ID.')),
          );
        });
      }
    } catch (e) {
      debugPrint("Error fetching gym owner details: $e");
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching gym owner details: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double usdToInrRate = 82.0; // Hardcoded exchange rate

    return Scaffold(
      appBar: AppBar(title: Text('Gym Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(widget.gymId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint("Error loading gym details: ${snapshot.error}");
                  return Center(child: Text('Error loading gym details.'));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  debugPrint("No gym details found for gymId: ${widget.gymId}");
                  return Center(child: Text('No gym details found.'));
                }

                final gymData = snapshot.data!.data() as Map<String, dynamic>;
                debugPrint("Gym data: $gymData");

                // Check and log the plans field
                final plans = gymData['plans'] as List<dynamic>?;
                if (plans == null || plans.isEmpty) {
                  debugPrint("No plans available for gymId: ${widget.gymId}");
                  return Center(child: Text('No plans available.'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          debugPrint("Plan $index: $plan");

                          // Convert price from USD to INR
                          final double priceInUsd = double.tryParse(plan['price'].toString()) ?? 0.0;
                          final double priceInInr = priceInUsd * usdToInrRate;

                          return ListTile(
                            title: Text(plan['name'] ?? 'Unknown Plan'),
                            subtitle: Text('Price: ₹${priceInInr.toStringAsFixed(2)}'), // Display in INR
                            trailing: ElevatedButton(
                              onPressed: !isLoading
                                  ? () {
                                      // Navigate to PaymentScreen for Razorpay integration
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentScreen(
                                            gymOwnerId: widget.gymId,
                                            userId: FirebaseAuth.instance.currentUser!.uid,
                                            amount: priceInInr, // Pass the price in INR
                                            planId: plan['name'] ?? 'Unknown',
                                            durationInDays: int.tryParse(plan['duration'].toString()) ?? 0,
                                          ),
                                        ),
                                      );
                                    }
                                  : null, // Disable button if data is not loaded
                              child: Text('Buy'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const GymOwnerDashboard()),
                        );
                      },
                      child: const Text('Complete Setup'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}





