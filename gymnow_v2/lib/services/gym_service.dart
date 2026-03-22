import 'package:cloud_firestore/cloud_firestore.dart';

class GymService {
  // Fetch gyms from Firestore
  Future<List<Map<String, dynamic>>> getGyms() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('gyms').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
