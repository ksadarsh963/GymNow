import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gym_detail_screen.dart';

class FindGymScreen extends StatefulWidget {
  const FindGymScreen({super.key});

  @override
  State<FindGymScreen> createState() => _FindGymScreenState();
}

class _FindGymScreenState extends State<FindGymScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> gymsList = [];
  List<QueryDocumentSnapshot> gymDocs = []; // Store Firestore documents

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchAllGyms();
    }); // Load all gyms initially
  }

  /// Fetch all gyms from Firestore
  Future<void> fetchAllGyms() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'gym_owner')
          .get();

      setState(() {
        gymDocs = querySnapshot.docs; // Store the documents
        gymsList = querySnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching gyms: $e");
    }
  }

  /// Search gyms based on any field (City, State, or Country)
  void searchGyms() async {
    String query = _searchController.text.trim().toLowerCase();

    try {
      List<Map<String, dynamic>> filteredGyms = [];
      List<QueryDocumentSnapshot> filteredDocs = [];

      for (int i = 0; i < gymDocs.length; i++) {
        var gym = gymsList[i];
        var city = gym['location']?['city']?.toLowerCase() ?? '';
        var state = gym['location']?['state']?.toLowerCase() ?? '';
        var country = gym['location']?['country']?.toLowerCase() ?? '';

        if (city.contains(query) || state.contains(query) || country.contains(query)) {
          filteredGyms.add(gym);
          filteredDocs.add(gymDocs[i]);
        }
      }

      setState(() {
        gymsList = filteredGyms;
        gymDocs = filteredDocs;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error searching gyms: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error searching gyms: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find Nearby Gyms")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search by City, State or Country",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Search Button
            ElevatedButton(
              onPressed: searchGyms,
              child: const Text("Find Gyms"),
            ),

            const SizedBox(height: 20),

            // Gym List View
            Expanded(
              child: gymsList.isEmpty
                  ? const Center(child: Text("No gyms found"))
                  : ListView.builder(
                      itemCount: gymsList.length,
                      itemBuilder: (context, index) {
                        var gym = gymsList[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center, size: 50),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(gym['name'] ?? 'Unknown Gym',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const Text('Gym Owner',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                            subtitle: Text(
                                "${gym['location']?['city'] ?? ''}, ${gym['location']?['state'] ?? ''}, ${gym['location']?['country'] ?? ''}"),
                            onTap: () {
                              // Pass the correct gymId (Firestore document ID)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GymDetailScreen(
                                    gymId: gymDocs[index].id, // Pass document ID
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}






