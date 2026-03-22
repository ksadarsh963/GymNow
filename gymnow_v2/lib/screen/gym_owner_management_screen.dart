import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GymOwnerManagementScreen extends StatefulWidget {
  const GymOwnerManagementScreen({super.key});
  @override
  GymOwnerManagementScreenState createState() => GymOwnerManagementScreenState();
}

class GymOwnerManagementScreenState extends State<GymOwnerManagementScreen> {
  final CollectionReference ownersRef =
      FirebaseFirestore.instance.collection('users');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Owner Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Gym Owner",
            onPressed: () => _showAddGymOwnerDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ownersRef.where('role', isEqualTo: 'gym_owner').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching gym owners'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No gym owners found'));
          }

          final owners = snapshot.data!.docs;

          return ListView.builder(
            itemCount: owners.length,
            itemBuilder: (context, index) {
              final owner = owners[index].data() as Map<String, dynamic>;
              final ownerId = owners[index].id;
              return ListTile(
                leading: const Icon(Icons.business, color: Colors.blueAccent),
                title: Text(owner['name'] ?? 'No Name'),
                subtitle: Text(owner['email'] ?? 'No Email'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteOwner(context, ownerId),
                ),
                onTap: () => _showOwnerDetails(context, owner),
              );
            },
          );
        },
      ),
    );
  }

  void _showOwnerDetails(BuildContext context, Map<String, dynamic> owner) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(owner['name'] ?? 'Owner Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${owner['email'] ?? 'N/A'}'),
              Text('Phone: ${owner['phone'] ?? 'N/A'}'),
              Text('Gym Name: ${owner['gym_name'] ?? 'N/A'}'),
              Text('Status: ${owner['status'] == true ? 'Active' : 'Inactive'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteOwner(BuildContext context, String ownerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Gym Owner'),
          content: const Text('Are you sure you want to delete this gym owner? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteGymOwner(ownerId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGymOwner(String ownerId) async {
    try {
      // Delete gym owner data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(ownerId).delete();

      // Optionally, delete any related subcollections (e.g., gym details, subscriptions)
      final gymDetailsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .collection('gym_details');
      final gymDetailsDocs = await gymDetailsCollection.get();
      for (var doc in gymDetailsDocs.docs) {
        await doc.reference.delete();
      }

      final subscriptionsCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .collection('subscriptions');
      final subscriptionDocs = await subscriptionsCollection.get();
      for (var doc in subscriptionDocs.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gym owner deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting gym owner: $e')),
        );
      }
    }
  }

  void _showAddGymOwnerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Gym Owner'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _addGymOwner,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addGymOwner() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save gym owner details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': 'gym_owner',
        'profileComplete': false,
        'hasSubscription': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gym owner added successfully')),
        );
      }
      if (!mounted) return;
      Navigator.pop(context); // Close the dialog
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding gym owner: $e')),
        );
      }
    }
  }
}
